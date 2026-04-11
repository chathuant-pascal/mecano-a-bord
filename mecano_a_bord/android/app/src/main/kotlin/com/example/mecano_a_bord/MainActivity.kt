package com.example.mecano_a_bord

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Activité principale Flutter.
 * Connexion OBD en Bluetooth classique (SPP) pour dongle iCar Pro Vgate appairé par PIN.
 * MethodChannel "com.example.mecano_a_bord/obd" : getBondedDevices, connect, disconnect, getConnectionState,
 * readVehicleDataStep, readLiveData (PID mode 01 : 0105, 0142, 010B, 010C), clearDtcCodes (mode 04), resetObdNativePrefs.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.mecano_a_bord/obd"
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        private const val ATZ_TIMEOUT_MS = 15000
        /** Après le premier ">" dans la réponse OBD, attente courte pour la fin des octets (sendObdCommand). */
        private const val OBD_POST_PROMPT_SETTLE_MS = 150L
        private const val OBD_CMD_TIMEOUT_MS = 45000
        private const val PROTOCOL_DETECTION_WAIT_MS = 90_000  // 1 min 30 par protocole
        private const val INIT_CMD_DELAY_MS = 500L  // 0,5 s entre chaque commande d'init ELM327 (tryProtocol)
        /** Pause après la réponse à ATZ uniquement (plus longue qu'INIT_CMD_DELAY_MS pour laisser le dongle se stabiliser). */
        private const val ATZ_POST_DELAY_MS = 1500L
        private const val INIT_CMD_READ_TIMEOUT_MS = 8000   // attente réponse par commande AT
        private const val PROTOCOL_TEST_CMD_TIMEOUT_MS = 15000  // attente max pour 0100 pendant détection
        private const val OBD_LOG_TAG = "MecanoOBD"
        private const val PREF_NAME = "obd"
        private const val KEY_PROTOCOL_PREFIX = "obd_protocol_"
        private val DTC_PREFIX = charArrayOf('P', 'C', 'B', 'U')
        private val STEP_CMDS = arrayOf("0101", "03", "07", "0A")
        private val STEP_RESPONSE_PREFIX = intArrayOf(0x41, 0x43, 0x47, 0x4A)
    }

    private fun prefs(): android.content.SharedPreferences =
        getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    private var obdSocket: BluetoothSocket? = null
    private var connectedDeviceName: String? = null
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBondedDevices" -> getBondedDevices(result)
                "connect" -> {
                    val address = call.argument<String>("address") ?: ""
                    val deviceName = call.argument<String>("deviceName")
                    val vin = call.argument<String>("vin")?.trim()?.takeIf { it.isNotEmpty() }
                    connect(address, deviceName, vin, result)
                }
                "tryProtocol" -> {
                    val vin = call.argument<String>("vin") ?: ""
                    val protocolIndex = call.argument<Int>("protocolIndex") ?: 0
                    tryProtocol(vin, protocolIndex.coerceIn(0, 9), result)
                }
                "disconnect" -> disconnect(result)
                "getConnectionState" -> getConnectionState(result)
                "readVehicleDataStep" -> {
                    val step = call.argument<Int>("step") ?: 0
                    readVehicleDataStep(step, result)
                }
                "readLiveData" -> {
                    val pid = call.argument<String>("pid") ?: ""
                    readLiveData(pid, result)
                }
                "clearDtcCodes" -> clearDtcCodes(result)
                "resetObdNativePrefs" -> resetObdNativePrefs(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun getBondedDevices(result: MethodChannel.Result) {
        executor.execute {
            try {
                val adapter = BluetoothAdapter.getDefaultAdapter()
                if (adapter == null) {
                    result.success(emptyList<Map<String, String>>())
                    return@execute
                }
                if (!adapter.isEnabled) {
                    result.success(emptyList<Map<String, String>>())
                    return@execute
                }
                val bonded = adapter.bondedDevices
                val list = bonded.map { device ->
                    mapOf(
                        "id" to (device.address),
                        "name" to (device.name ?: "OBD (${device.address.take(8)})")
                    )
                }
                result.success(list)
            } catch (e: Exception) {
                result.error("GET_BONDED", e.message, null)
            }
        }
    }

    private fun connect(address: String, deviceName: String?, vin: String?, result: MethodChannel.Result) {
        if (address.isBlank()) {
            result.error("INVALID", "Adresse requise", null)
            return
        }
        executor.execute {
            try {
                disconnectSync()
                val adapter = BluetoothAdapter.getDefaultAdapter()
                    ?: throw IOException("Bluetooth non disponible")
                if (!adapter.isEnabled) {
                    result.error("OFF", "Bluetooth désactivé", null)
                    return@execute
                }
                val device: BluetoothDevice? = adapter.getRemoteDevice(address)
                if (device == null) {
                    result.error("NOT_FOUND", "Appareil non trouvé", null)
                    return@execute
                }
                val name = deviceName ?: device.name ?: address
                val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                try {
                    socket.connect()
                } catch (e: IOException) {
                    try {
                        socket.close()
                    } catch (_: IOException) {}
                    val fallback = device.javaClass.getMethod(
                        "createRfcommSocket",
                        Int::class.javaPrimitiveType
                    ).invoke(device, 1) as BluetoothSocket
                    fallback.connect()
                    obdSocket = fallback
                    connectedDeviceName = name
                    runOnUiThread { sendAtzAndComplete(result, fallback, name, vin) }
                    return@execute
                }
                obdSocket = socket
                connectedDeviceName = name
                runOnUiThread { sendAtzAndComplete(result, socket, name, vin) }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("CONNECT", e.message ?: "Erreur de connexion", null)
                }
            }
        }
    }

    private fun sendAtzAndComplete(result: MethodChannel.Result, socket: BluetoothSocket, deviceName: String, vin: String?) {
        executor.execute {
            try {
                val out: OutputStream = socket.outputStream
                val inp: InputStream = socket.inputStream
                out.write("ATZ\r".toByteArray(Charsets.US_ASCII))
                out.flush()
                val buffer = ByteArray(512)
                val start = System.currentTimeMillis()
                val sb = StringBuilder()
                // Lire jusqu'au prompt ">" uniquement (pas ELM327/OK seuls : la ligne peut continuer).
                while (System.currentTimeMillis() - start < ATZ_TIMEOUT_MS) {
                    if (inp.available() > 0) {
                        val n = inp.read(buffer)
                        if (n > 0) {
                            sb.append(String(buffer, 0, n, Charsets.US_ASCII))
                            if (sb.contains(">")) {
                                applyProtocolAndComplete(result, out, inp, deviceName, vin)
                                return@execute
                            }
                        }
                    }
                    Thread.sleep(100)
                }
                runOnUiThread {
                    disconnectSync()
                    result.error("ATZ_TIMEOUT", "Pas de réponse du dongle (ATZ)", null)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    disconnectSync()
                    result.error("ATZ", e.message ?: "Erreur ATZ", null)
                }
            }
        }
    }

    /** Après ATZ : si un VIN est fourni, charge le protocole enregistré ou indique qu'une détection est nécessaire. */
    private fun applyProtocolAndComplete(
        result: MethodChannel.Result,
        out: OutputStream,
        inp: InputStream,
        deviceName: String,
        vin: String?
    ) {
        if (vin.isNullOrBlank()) {
            runOnUiThread { result.success(mapOf("connected" to true, "deviceName" to deviceName)) }
            return
        }
        val saved = prefs().getInt(KEY_PROTOCOL_PREFIX + vin, -1)
        if (saved in 0..9) {
            // Même logique d'init que tryProtocol / readVehicleDataStep, puis ATSP enregistré.
            sendAtCommandAndWait(out, inp, "ATE0", INIT_CMD_DELAY_MS)
            sendAtCommandAndWait(out, inp, "ATL0", INIT_CMD_DELAY_MS)
            sendAtCommandAndWait(out, inp, "ATH0", INIT_CMD_DELAY_MS)
            sendAtCommandAndWait(out, inp, "ATAT1", INIT_CMD_DELAY_MS)
            sendAtCommandAndWait(out, inp, "ATSP$saved", INIT_CMD_DELAY_MS)
            runOnUiThread { result.success(mapOf("connected" to true, "deviceName" to deviceName)) }
            return
        }
        runOnUiThread {
            result.success(mapOf(
                "connected" to true,
                "deviceName" to deviceName,
                "protocolDetectionNeeded" to true
            ))
        }
    }

    /**
     * Envoie une commande AT au dongle, lit jusqu'au prompt ">" ou timeout,
     * puis attend [delayAfterMs]. Retourne la réponse brute (pour logs).
     */
    private fun sendAtCommandAndWait(
        out: OutputStream,
        inp: InputStream,
        cmd: String,
        delayAfterMs: Long
    ): String {
        out.write("$cmd\r".toByteArray(Charsets.US_ASCII))
        out.flush()
        val buffer = ByteArray(256)
        val sb = StringBuilder()
        val t0 = System.currentTimeMillis()
        while (System.currentTimeMillis() - t0 < INIT_CMD_READ_TIMEOUT_MS) {
            if (inp.available() > 0) {
                val n = inp.read(buffer)
                if (n > 0) sb.append(String(buffer, 0, n, Charsets.US_ASCII))
            }
            if (sb.contains(">")) break
            Thread.sleep(150)
        }
        Thread.sleep(delayAfterMs)
        return sb.toString()
    }

    /**
     * Envoie une commande OBD (ex. 0100) et lit la réponse avec un timeout court.
     * Utilisé pendant la détection de protocole.
     */
    private fun sendObdCommandForDetection(out: OutputStream, inp: InputStream, cmd: String): String {
        out.write("$cmd\r".toByteArray(Charsets.US_ASCII))
        out.flush()
        val buffer = ByteArray(256)
        val sb = StringBuilder()
        val t0 = System.currentTimeMillis()
        while (System.currentTimeMillis() - t0 < PROTOCOL_TEST_CMD_TIMEOUT_MS) {
            if (inp.available() > 0) {
                val n = inp.read(buffer)
                if (n > 0) sb.append(String(buffer, 0, n, Charsets.US_ASCII))
            }
            if (sb.contains(">")) break
            Thread.sleep(150)
        }
        return sb.toString()
    }

    /**
     * Valide qu'une réponse OBD indique une communication réussie :
     * réponse non vide, sans ERROR, UNABLE, NO DATA ni "?".
     */
    private fun isProtocolResponseValid(raw: String): Boolean {
        val r = raw.uppercase().trim()
        if (r.isEmpty()) return false
        if (r.contains("ERROR")) return false
        if (r.contains("UNABLE")) return false
        if (r.contains("NO DATA") || r.contains("NODATA")) return false
        if (r.contains("?")) return false
        return true
    }

    /**
     * Teste le protocole [protocolIndex] (0..9).
     * 1) Séquence d'init ELM327 : ATZ (puis pause ATZ_POST_DELAY_MS), ATE0, ATL0, ATH0, ATAT1, ATSPx (INIT_CMD_DELAY_MS entre les autres commandes).
     * 2) Envoie 0100 et considère succès si la réponse est non vide et sans ERROR/UNABLE/NO DATA/?.
     * 3) Log la réponse brute pour chaque protocole.
     */
    private fun tryProtocol(vin: String, protocolIndex: Int, result: MethodChannel.Result) {
        executor.execute {
            val socket = obdSocket
            if (socket == null || !socket.isConnected || vin.isBlank()) {
                runOnUiThread {
                    result.success(mapOf("success" to false, "protocolIndex" to protocolIndex, "rawResponse" to ""))
                }
                return@execute
            }
            try {
                val out = socket.outputStream
                val inp = socket.inputStream

                // 1) Séquence d'initialisation ELM327 (ordre fixe ; pause 1,5 s après ATZ uniquement)
                sendAtCommandAndWait(out, inp, "ATZ", ATZ_POST_DELAY_MS)
                sendAtCommandAndWait(out, inp, "ATE0", INIT_CMD_DELAY_MS)
                sendAtCommandAndWait(out, inp, "ATL0", INIT_CMD_DELAY_MS)
                sendAtCommandAndWait(out, inp, "ATH0", INIT_CMD_DELAY_MS)
                sendAtCommandAndWait(out, inp, "ATAT1", INIT_CMD_DELAY_MS)
                sendAtCommandAndWait(out, inp, "ATSP$protocolIndex", INIT_CMD_DELAY_MS)

                // 2) Test du protocole : commande 0100 (supported PIDs)
                val testRaw = sendObdCommandForDetection(out, inp, "0100")
                Log.d(OBD_LOG_TAG, "Protocol $protocolIndex response: $testRaw")

                val ok = isProtocolResponseValid(testRaw)
                if (ok) {
                    prefs().edit().putInt(KEY_PROTOCOL_PREFIX + vin, protocolIndex).apply()
                }
                runOnUiThread {
                    result.success(mapOf(
                        "success" to ok,
                        "protocolIndex" to protocolIndex,
                        "rawResponse" to testRaw
                    ))
                }
            } catch (e: Exception) {
                Log.d(OBD_LOG_TAG, "Protocol $protocolIndex exception: ${e.message}")
                runOnUiThread {
                    result.success(mapOf(
                        "success" to false,
                        "protocolIndex" to protocolIndex,
                        "rawResponse" to (e.message ?: "")
                    ))
                }
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        executor.execute {
            disconnectSync()
            runOnUiThread { result.success(null) }
        }
    }

    private fun disconnectSync() {
        try {
            obdSocket?.close()
        } catch (_: IOException) {}
        obdSocket = null
        connectedDeviceName = null
    }

    private fun getConnectionState(result: MethodChannel.Result) {
        val socket = obdSocket
        val name = connectedDeviceName
        result.success(
            if (socket != null && socket.isConnected) {
                mapOf("connected" to true, "deviceName" to (name ?: "OBD"))
            } else {
                mapOf("connected" to false)
            }
        )
    }

    /** Vide les préférences Android « obd » (protocoles ATSP par VIN, etc.). */
    private fun resetObdNativePrefs(result: MethodChannel.Result) {
        executor.execute {
            try {
                prefs().edit().clear().apply()
                runOnUiThread { result.success(null) }
            } catch (_: Exception) {
                runOnUiThread { result.success(null) }
            }
        }
    }

    /**
     * Envoie une commande OBD et lit la réponse.
     * Dès que le prompt ">" apparaît, lecture encore pendant [OBD_POST_PROMPT_SETTLE_MS] pour les derniers octets, puis sortie.
     * Plafond : `OBD_CMD_TIMEOUT_MS`.
     */
    private fun sendObdCommand(out: OutputStream, inp: InputStream, cmd: String): String {
        out.write("$cmd\r".toByteArray(Charsets.US_ASCII))
        out.flush()
        val buffer = ByteArray(256)
        val sb = StringBuilder()
        val start = System.currentTimeMillis()
        var settleEnd: Long? = null
        while (true) {
            val now = System.currentTimeMillis()
            val elapsed = now - start
            if (inp.available() > 0) {
                val n = inp.read(buffer)
                if (n > 0) sb.append(String(buffer, 0, n, Charsets.US_ASCII))
            }
            if (settleEnd == null && sb.contains(">")) {
                settleEnd = now + OBD_POST_PROMPT_SETTLE_MS
            }
            if (settleEnd != null && now >= settleEnd) break
            if (elapsed >= OBD_CMD_TIMEOUT_MS) break
            Thread.sleep(if (settleEnd == null) 150 else 10)
        }
        return sb.toString()
    }

    /** Extrait les octets hex (paires) d'une réponse OBD (ex. "41 01 00 00" -> [0x41, 0x01, 0x00, 0x00]). */
    private fun parseHexBytes(raw: String): IntArray {
        val s = raw.replace(Regex("[^0-9A-Fa-f]"), "")
        return (0 until s.length step 2).mapNotNull { i ->
            if (i + 1 < s.length) s.substring(i, i + 2).toIntOrNull(16) else null
        }.toIntArray()
    }

    private fun unitForLivePid(pid: String): String = when (pid) {
        "0105" -> "°C"
        "0142" -> "V"
        "010B" -> "kPa"
        "010C" -> "RPM"
        else -> ""
    }

    /** Réponse brute invalide pour une lecture PID (NO DATA, erreur ELM, etc.). */
    private fun isLiveDataRawInvalid(raw: String): Boolean {
        val u = raw.uppercase()
        if (u.isBlank()) return true
        if (u.contains("NO DATA") || u.contains("NODATA")) return true
        if (u.contains("ERROR")) return true
        if (u.contains("UNABLE")) return true
        if (u.contains("?")) return true
        return false
    }

    /**
     * Lecture d'un PID mode 01 (0105 température, 0142 tension, 010B pression kPa, 010C régime moteur RPM).
     * Retour : success, value, unit, supported.
     */
    private fun readLiveData(pid: String, result: MethodChannel.Result) {
        executor.execute {
            val socket = obdSocket
            if (socket == null || !socket.isConnected) {
                runOnUiThread {
                    result.success(
                        mapOf(
                            "success" to false,
                            "value" to 0.0,
                            "unit" to "",
                            "supported" to false
                        )
                    )
                }
                return@execute
            }
            val normalized = pid.trim().uppercase().replace(" ", "")
            if (normalized !in setOf("0105", "0142", "010B", "010C")) {
                runOnUiThread {
                    result.success(
                        mapOf(
                            "success" to false,
                            "value" to 0.0,
                            "unit" to "",
                            "supported" to false
                        )
                    )
                }
                return@execute
            }
            try {
                val out = socket.outputStream
                val inp = socket.inputStream
                sendAtCommandAndWait(out, inp, "ATE0", 500L)
                sendAtCommandAndWait(out, inp, "ATL0", 500L)
                sendAtCommandAndWait(out, inp, "ATH0", 500L)
                sendAtCommandAndWait(out, inp, "ATAT1", 500L)
                val raw = sendObdCommand(out, inp, normalized)
                if (isLiveDataRawInvalid(raw)) {
                    runOnUiThread {
                        result.success(
                            mapOf(
                                "success" to false,
                                "value" to 0.0,
                                "unit" to unitForLivePid(normalized),
                                "supported" to false
                            )
                        )
                    }
                    return@execute
                }
                val bytes = parseHexBytes(raw)
                val pidByte2 = normalized.takeLast(2).toInt(16)
                var idx = -1
                for (i in 0 until bytes.size - 1) {
                    if (bytes[i] == 0x41 && bytes[i + 1] == pidByte2) {
                        idx = i
                        break
                    }
                }
                if (idx < 0) {
                    runOnUiThread {
                        result.success(
                            mapOf(
                                "success" to false,
                                "value" to 0.0,
                                "unit" to unitForLivePid(normalized),
                                "supported" to false
                            )
                        )
                    }
                    return@execute
                }
                when (normalized) {
                    "0105" -> {
                        if (idx + 2 >= bytes.size) {
                            unsupportedLive(result, normalized)
                            return@execute
                        }
                        val a = bytes[idx + 2]
                        val celsius = (a - 40).toDouble()
                        runOnUiThread {
                            result.success(
                                mapOf(
                                    "success" to true,
                                    "value" to celsius,
                                    "unit" to "°C",
                                    "supported" to true
                                )
                            )
                        }
                    }
                    "0142" -> {
                        if (idx + 3 >= bytes.size) {
                            unsupportedLive(result, normalized)
                            return@execute
                        }
                        val a = bytes[idx + 2]
                        val b = bytes[idx + 3]
                        val volts = (a * 256 + b) / 1000.0
                        runOnUiThread {
                            result.success(
                                mapOf(
                                    "success" to true,
                                    "value" to volts,
                                    "unit" to "V",
                                    "supported" to true
                                )
                            )
                        }
                    }
                    "010B" -> {
                        if (idx + 2 >= bytes.size) {
                            unsupportedLive(result, normalized)
                            return@execute
                        }
                        val a = bytes[idx + 2]
                        val kpa = a.toDouble()
                        runOnUiThread {
                            result.success(
                                mapOf(
                                    "success" to true,
                                    "value" to kpa,
                                    "unit" to "kPa",
                                    "supported" to true
                                )
                            )
                        }
                    }
                    "010C" -> {
                        if (idx + 3 >= bytes.size) {
                            unsupportedLive(result, normalized)
                            return@execute
                        }
                        val a = bytes[idx + 2]
                        val b = bytes[idx + 3]
                        val rpm = ((a * 256) + b) / 4.0
                        runOnUiThread {
                            result.success(
                                mapOf(
                                    "success" to true,
                                    "value" to rpm,
                                    "unit" to "RPM",
                                    "supported" to true
                                )
                            )
                        }
                    }
                    else -> unsupportedLive(result, normalized)
                }
            } catch (e: Exception) {
                Log.d(OBD_LOG_TAG, "readLiveData exception: ${e.message}")
                runOnUiThread {
                    result.success(
                        mapOf(
                            "success" to false,
                            "value" to 0.0,
                            "unit" to unitForLivePid(normalized),
                            "supported" to false
                        )
                    )
                }
            }
        }
    }

    private fun unsupportedLive(result: MethodChannel.Result, pid: String) {
        runOnUiThread {
            result.success(
                mapOf(
                    "success" to false,
                    "value" to 0.0,
                    "unit" to unitForLivePid(pid),
                    "supported" to false
                )
            )
        }
    }

    /** Réponse brute invalide pour la commande mode 04 (effacement codes). */
    private fun isClearDtcRawInvalid(raw: String): Boolean {
        val u = raw.uppercase()
        if (u.isBlank()) return true
        if (u.contains("NO DATA") || u.contains("NODATA")) return true
        if (u.contains("ERROR")) return true
        if (u.contains("UNABLE")) return true
        if (u.contains("?")) return true
        return false
    }

    /**
     * OBD-II mode 04 — efface les codes défaut stockés (commande ELM « 04 »).
     * Succès si au moins un octet 0x44 (réponse positive au service 04) est présent dans la trame.
     */
    private fun clearDtcCodes(result: MethodChannel.Result) {
        executor.execute {
            val socket = obdSocket
            if (socket == null || !socket.isConnected) {
                runOnUiThread { result.success(mapOf("success" to false)) }
                return@execute
            }
            try {
                val out = socket.outputStream
                val inp = socket.inputStream
                sendAtCommandAndWait(out, inp, "ATE0", 500L)
                sendAtCommandAndWait(out, inp, "ATL0", 500L)
                sendAtCommandAndWait(out, inp, "ATH0", 500L)
                sendAtCommandAndWait(out, inp, "ATAT1", 500L)
                val raw = sendObdCommand(out, inp, "04")
                if (isClearDtcRawInvalid(raw)) {
                    runOnUiThread { result.success(mapOf("success" to false)) }
                    return@execute
                }
                val bytes = parseHexBytes(raw)
                val ok = bytes.any { it == 0x44 }
                runOnUiThread { result.success(mapOf("success" to ok)) }
            } catch (_: Exception) {
                runOnUiThread { result.success(mapOf("success" to false)) }
            }
        }
    }

    /** Décode un DTC à partir de 2 octets (ex. 0x01, 0x23 -> P0123). */
    private fun decodeDtc(b1: Int, b2: Int): String {
        val type = (b1 shr 4) and 0x03
        val d1 = b1 and 0x0F
        val d2 = (b2 shr 4) and 0x0F
        val d3 = b2 and 0x0F
        return "${DTC_PREFIX[type]}$d1$d2$d3"
    }

    /** Une étape de lecture : step 0=01, 1=03, 2=07, 3=0A. Retourne success=true seulement si réponse OBD valide. */
    private fun readVehicleDataStep(step: Int, result: MethodChannel.Result) {
        executor.execute {
            val socket = obdSocket
            if (socket == null || !socket.isConnected) {
                runOnUiThread { result.error("NOT_CONNECTED", "Non connecté", null) }
                return@execute
            }
            val safeStep = step.coerceIn(0, STEP_CMDS.size - 1)
            try {
                val out = socket.outputStream
                val inp = socket.inputStream
                // Mini-init ELM327 avant chaque commande de lecture véhicule (écho off, LF off, headers off, adaptive timing on).
                sendAtCommandAndWait(out, inp, "ATE0", 500L)
                sendAtCommandAndWait(out, inp, "ATL0", 500L)
                sendAtCommandAndWait(out, inp, "ATH0", 500L)
                sendAtCommandAndWait(out, inp, "ATAT1", 500L)
                val cmd = STEP_CMDS[safeStep]
                val raw = sendObdCommand(out, inp, cmd)
                val bytes = parseHexBytes(raw)
                val expectedFirst = STEP_RESPONSE_PREFIX[safeStep]
                val hasValidResponse = bytes.isNotEmpty() && bytes[0] == expectedFirst &&
                    (safeStep != 0 || (bytes.size >= 2 && bytes[1] == 0x01))
                var milOn = false
                var dtcCount = 0
                val dtcList = mutableListOf<String>()
                if (hasValidResponse) {
                    when (safeStep) {
                        0 -> if (bytes.size >= 4) {
                            val a = bytes[2]
                            milOn = (a and 0x80) != 0
                            dtcCount = a and 0x7F
                        }
                        1, 2, 3 -> if (bytes.size >= 2) {
                            val n = bytes[1]
                            var i = 2
                            while (i + 1 < bytes.size && dtcList.size < n) {
                                dtcList.add(decodeDtc(bytes[i], bytes[i + 1]))
                                i += 2
                            }
                        }
                    }
                }
                runOnUiThread {
                    result.success(mapOf(
                        "success" to hasValidResponse,
                        "milOn" to milOn,
                        "dtcCount" to dtcCount,
                        "dtcs" to dtcList
                    ))
                }
            } catch (e: Exception) {
                runOnUiThread {
                    result.success(mapOf(
                        "success" to false,
                        "milOn" to false,
                        "dtcCount" to 0,
                        "dtcs" to emptyList<String>()
                    ))
                }
            }
        }
    }

    override fun onDestroy() {
        executor.execute { disconnectSync() }
        super.onDestroy()
    }
}
