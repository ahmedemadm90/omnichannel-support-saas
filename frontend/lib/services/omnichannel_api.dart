import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/inbox_models.dart';

class OmnichannelApi {
  OmnichannelApi({http.Client? client, this.baseUrl = 'http://10.0.2.2:8000/api/v1'}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  String? token;

  Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<int> login({required String email, required String password}) async {
    final response = await _client.post(Uri.parse('$baseUrl/auth/login'), headers: headers, body: jsonEncode({'email': email, 'password': password}));
    _check(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    token = json['token'] as String;
    final workspaces = json['workspaces'] as List<dynamic>? ?? [];
    return int.tryParse((workspaces.first as Map<String, dynamic>)['id'].toString()) ?? 0;
  }

  Future<List<InboxConversation>> conversations(int workspaceId, {String status = 'open'}) async {
    final response = await _client.get(Uri.parse('$baseUrl/workspaces/$workspaceId/conversations?status=$status'), headers: headers);
    _check(response);
    final data = (jsonDecode(response.body) as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((item) => InboxConversation.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<InboxConversation> conversation(int workspaceId, int conversationId) async {
    final response = await _client.get(Uri.parse('$baseUrl/workspaces/$workspaceId/conversations/$conversationId'), headers: headers);
    _check(response);
    return InboxConversation.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<InboxMessage> reply(int workspaceId, int conversationId, String body) async {
    final response = await _client.post(Uri.parse('$baseUrl/workspaces/$workspaceId/conversations/$conversationId/messages'), headers: headers, body: jsonEncode({'body': body}));
    _check(response);
    return InboxMessage.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateStatus(int workspaceId, int conversationId, {required String status, String priority = 'normal'}) async {
    final response = await _client.patch(Uri.parse('$baseUrl/workspaces/$workspaceId/conversations/$conversationId'), headers: headers, body: jsonEncode({'status': status, 'priority': priority}));
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) throw OmnichannelApiException('API error ${response.statusCode}: ${response.body}');
  }
}

class OmnichannelApiException implements Exception {
  const OmnichannelApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
