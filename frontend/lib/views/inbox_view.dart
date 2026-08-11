import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/inbox_models.dart';
import '../providers/inbox_provider.dart';

class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<InboxProvider>().connectDemo());
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InboxProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Row(children: [Icon(Icons.support_agent_rounded, color: Color(0xFF0B8F80)), SizedBox(width: 10), Text('OmniDesk', style: TextStyle(fontWeight: FontWeight.w800))]),
        actions: [IconButton(onPressed: provider.connectDemo, icon: const Icon(Icons.refresh_rounded)), const SizedBox(width: 8)],
      ),
      body: provider.loading && provider.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (provider.error != null) _ErrorBanner(provider.error!),
              _StatsHeader(count: provider.conversations.length),
              _FilterBar(provider: provider),
              Expanded(child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;
                return Row(children: [
                  SizedBox(width: wide ? 360 : constraints.maxWidth, child: _ConversationList(provider: provider)),
                  if (wide) Expanded(child: _ConversationPanel(provider: provider)),
                ]);
              })),
            ]),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, color: Colors.white, padding: const EdgeInsets.fromLTRB(18, 18, 18, 14), child: Row(children: [const Text('Unified inbox', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFE3F7F4), borderRadius: BorderRadius.circular(20)), child: Text('$count active', style: const TextStyle(color: Color(0xFF087A6D), fontWeight: FontWeight.w700)))]));
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.provider});
  final InboxProvider provider;
  @override
  Widget build(BuildContext context) => Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: Row(children: ['open', 'pending', 'resolved'].map((value) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(value[0].toUpperCase() + value.substring(1)), selected: provider.filter == value, onSelected: (_) => provider.setFilter(value)))).toList()));
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.provider});
  final InboxProvider provider;
  @override
  Widget build(BuildContext context) {
    if (provider.conversations.isEmpty) return const Center(child: Text('No conversations in this view.'));
    return Container(color: const Color(0xFFF8F9FC), child: ListView.separated(padding: const EdgeInsets.all(12), itemCount: provider.conversations.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
      final item = provider.conversations[index];
      final selected = item.id == provider.activeConversation?.id;
      return Material(color: selected ? const Color(0xFFE4F6F2) : Colors.white, borderRadius: BorderRadius.circular(16), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => provider.openConversation(item.id), child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: const Color(0xFFDBF2EE), child: Text(item.contact.name.isEmpty ? '?' : item.contact.name[0], style: const TextStyle(color: Color(0xFF087A6D), fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(item.contact.name, style: const TextStyle(fontWeight: FontWeight.w800))), _ChannelBadge(item.channel)]), const SizedBox(height: 5), Text(item.latestMessage?.body ?? 'No messages yet', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 8), Row(children: [Icon(item.priority == 'high' ? Icons.priority_high_rounded : Icons.schedule_rounded, size: 14, color: item.priority == 'high' ? Colors.orange : Colors.black38), const SizedBox(width: 4), Text(item.priority, style: const TextStyle(fontSize: 11, color: Colors.black54))])]))
      ]))));
    }));
  }
}

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({required this.provider});
  final InboxProvider provider;
  @override
  Widget build(BuildContext context) {
    final conversation = provider.activeConversation;
    if (conversation == null) return const Center(child: Text('Select a conversation to start replying.'));
    return Container(margin: const EdgeInsets.fromLTRB(0, 12, 12, 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(children: [
      Padding(padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(backgroundColor: const Color(0xFFDBF2EE), child: Text(conversation.contact.name[0])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(conversation.contact.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), Text(conversation.contact.email ?? conversation.contact.phone ?? 'Customer', style: const TextStyle(color: Colors.black54, fontSize: 12))])), OutlinedButton.icon(onPressed: provider.resolveActive, icon: const Icon(Icons.check_rounded, size: 18), label: const Text('Resolve'))])),
      const Divider(height: 1),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(18), itemCount: conversation.messages.length, itemBuilder: (context, index) => _Bubble(message: conversation.messages[index]))),
      Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 14), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: TextField(controller: _replyController(context), minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Reply to customer...', filled: true))), const SizedBox(width: 8), IconButton.filled(onPressed: provider.sending ? null : () => _send(context), icon: provider.sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded))]))
    ]));
  }

  static final Map<int, TextEditingController> _controllers = {};
  TextEditingController _replyController(BuildContext context) => _controllers.putIfAbsent(provider.activeConversation?.id ?? 0, TextEditingController.new);
  Future<void> _send(BuildContext context) async { final controller = _replyController(context); if (controller.text.trim().isEmpty) return; final text = controller.text; controller.clear(); await provider.sendReply(text); }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final InboxMessage message;
  @override
  Widget build(BuildContext context) { final agent = message.senderType == 'agent'; return Align(alignment: agent ? Alignment.centerRight : Alignment.centerLeft, child: Container(constraints: const BoxConstraints(maxWidth: 500), margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: agent ? const Color(0xFF0B8F80) : const Color(0xFFF1F3F7), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(message.body, style: TextStyle(color: agent ? Colors.white : const Color(0xFF242633), height: 1.35)), const SizedBox(height: 4), Text(DateFormat('HH:mm').format(message.createdAt.toLocal()), style: TextStyle(fontSize: 10, color: agent ? Colors.white70 : Colors.black45))]))); }
}

class _ChannelBadge extends StatelessWidget {
  const _ChannelBadge(this.channel);
  final String channel;
  @override
  Widget build(BuildContext context) { final icons = {'whatsapp': Icons.chat_rounded, 'telegram': Icons.send_rounded, 'email': Icons.mail_rounded}; return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icons[channel] ?? Icons.language_rounded, size: 14, color: const Color(0xFF0B8F80)), const SizedBox(width: 3), Text(channel, style: const TextStyle(fontSize: 10, color: Color(0xFF0B8F80), fontWeight: FontWeight.w700))]); }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, color: const Color(0xFFFFE9E9), padding: const EdgeInsets.all(10), child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9D2828))));
}
