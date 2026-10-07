class ChatMessage {
  ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.audioUrl,
    this.isMe = false,
  });

  final String id;
  final String requestId;
  final String senderId;
  final String senderName;
  final String text;
  final String? audioUrl;
  final DateTime sentAt;
  final bool isMe;

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'audioUrl': audioUrl,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] ?? json['_id']).toString(),
        requestId: json['requestId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String? ?? '',
        audioUrl: json['audioUrl'] as String?,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}
