// Modèle pour l'écran de chat IA — Mécano à Bord

enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime date;

  const ChatMessage({
    required this.text,
    required this.sender,
    required this.date,
  });
}
