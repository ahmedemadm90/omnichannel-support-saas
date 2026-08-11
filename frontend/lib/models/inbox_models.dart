class SupportContact {
  const SupportContact({required this.id, required this.name, this.email, this.phone, this.avatarUrl});
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  factory SupportContact.fromJson(Map<String, dynamic> json) => SupportContact(
        id: int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] as String? ?? 'Unknown customer',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class InboxMessage {
  const InboxMessage({required this.id, required this.body, required this.senderType, required this.createdAt, this.senderName});
  final int id;
  final String body;
  final String senderType;
  final DateTime createdAt;
  final String? senderName;

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return InboxMessage(
      id: int.tryParse(json['id'].toString()) ?? 0,
      body: json['body'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? 'contact',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      senderName: sender?['name'] as String?,
    );
  }
}

class InboxConversation {
  const InboxConversation({required this.id, required this.channel, required this.status, required this.priority, required this.contact, required this.messages, this.subject});
  final int id;
  final String channel;
  final String status;
  final String priority;
  final SupportContact contact;
  final List<InboxMessage> messages;
  final String? subject;

  InboxMessage? get latestMessage => messages.isEmpty ? null : messages.last;

  factory InboxConversation.fromJson(Map<String, dynamic> json) {
    final messages = (json['messages'] as List<dynamic>? ?? []).map((item) => InboxMessage.fromJson(item as Map<String, dynamic>)).toList();
    return InboxConversation(
      id: int.tryParse(json['id'].toString()) ?? 0,
      channel: json['channel'] as String? ?? 'web',
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String? ?? 'normal',
      contact: SupportContact.fromJson((json['contact'] as Map<String, dynamic>?) ?? {}),
      messages: messages,
      subject: json['subject'] as String?,
    );
  }
}
