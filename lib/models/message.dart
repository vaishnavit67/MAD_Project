class Message {
  final String id;
  final String senderName;
  final String lastMessage;
  final String time;
  final bool isUnread;
  final String? avatarUrl;

  Message({
    required this.id,
    required this.senderName,
    required this.lastMessage,
    required this.time,
    this.isUnread = false,
    this.avatarUrl,
  });
}
