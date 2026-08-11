import 'package:flutter/foundation.dart';

import '../models/inbox_models.dart';
import '../services/omnichannel_api.dart';

class InboxProvider extends ChangeNotifier {
  InboxProvider({OmnichannelApi? api}) : _api = api ?? OmnichannelApi();

  final OmnichannelApi _api;
  final List<InboxConversation> _conversations = [];
  int? _workspaceId;
  int? _activeConversationId;
  InboxConversation? _activeConversation;
  bool _loading = false;
  bool _sending = false;
  String _filter = 'open';
  String? _error;

  List<InboxConversation> get conversations => List.unmodifiable(_conversations);
  InboxConversation? get activeConversation => _activeConversation;
  bool get loading => _loading;
  bool get sending => _sending;
  String get filter => _filter;
  String? get error => _error;

  Future<void> connectDemo() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _workspaceId = await _api.login(email: 'owner@omnichannel.test', password: 'password');
      await refresh();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_workspaceId == null) return;
    _conversations
      ..clear()
      ..addAll(await _api.conversations(_workspaceId!, status: _filter));
    if (_activeConversationId != null) await openConversation(_activeConversationId!);
    notifyListeners();
  }

  Future<void> setFilter(String value) async {
    _filter = value;
    _loading = true;
    notifyListeners();
    try {
      await refresh();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> openConversation(int id) async {
    if (_workspaceId == null) return;
    _activeConversationId = id;
    try {
      _activeConversation = await _api.conversation(_workspaceId!, id);
    } catch (error) {
      _error = error.toString();
    }
    notifyListeners();
  }

  Future<void> sendReply(String body) async {
    if (_workspaceId == null || _activeConversationId == null || body.trim().isEmpty) return;
    _sending = true;
    notifyListeners();
    try {
      await _api.reply(_workspaceId!, _activeConversationId!, body.trim());
      await openConversation(_activeConversationId!);
    } catch (error) {
      _error = error.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> resolveActive() async {
    if (_workspaceId == null || _activeConversationId == null) return;
    await _api.updateStatus(_workspaceId!, _activeConversationId!, status: 'resolved', priority: _activeConversation?.priority ?? 'normal');
    await setFilter(_filter);
  }
}
