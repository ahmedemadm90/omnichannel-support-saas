import 'package:flutter_test/flutter_test.dart';
import 'package:omnichannel_support/models/inbox_models.dart';

void main() {
  test('parses an inbox conversation with contact and latest message', () {
    final conversation = InboxConversation.fromJson({
      'id': 4,
      'channel': 'whatsapp',
      'status': 'open',
      'priority': 'high',
      'contact': {'id': 9, 'name': 'Nour Ali', 'email': 'nour@example.com'},
      'messages': [
        {'id': 1, 'body': 'Need help', 'sender_type': 'contact', 'created_at': '2026-08-11T10:00:00Z'},
        {'id': 2, 'body': 'I am checking', 'sender_type': 'agent', 'created_at': '2026-08-11T10:01:00Z', 'sender': {'name': 'Omar'}},
      ],
    });

    expect(conversation.contact.name, 'Nour Ali');
    expect(conversation.channel, 'whatsapp');
    expect(conversation.priority, 'high');
    expect(conversation.latestMessage?.body, 'I am checking');
  });
}
