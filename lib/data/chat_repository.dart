import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/models.dart';
import 'health_repository.dart';

class ChatRepository {
  ChatRepository(this._c);
  final SupabaseClient _c;

  Stream<List<Message>> messages(ChatKey key) {
    return _c
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('child_id', key.childId)
        .order('created_at', ascending: true)
        .map((rows) => rows
            .where((r) => r['clinic_id'] == key.clinicId)
            .map(Message.fromJson)
            .toList());
  }

  Future<void> send({
    required ChatKey key,
    required String senderRole,
    String? body,
    String? attachmentPath,
  }) async {
    await _c.from('messages').insert({
      'clinic_id': key.clinicId,
      'child_id': key.childId,
      'sender_role': senderRole,
      'body': body,
      'attachment_path': attachmentPath,
    });
  }

  Future<String> uploadAttachment({
    required String childId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$childId/chat/${DateTime.now().millisecondsSinceEpoch}_${safeName(fileName)}';
    await _c.storage
        .from(AppConfig.storageBucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeOf(fileName)));
    return path;
  }

  /// Marks messages sent by the *other* party as read.
  Future<void> markRead(ChatKey key, String myRole) async {
    await _c
        .from('messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('child_id', key.childId)
        .eq('clinic_id', key.clinicId)
        .neq('sender_role', myRole)
        .isFilter('read_at', null);
  }

  Future<int> unreadFromDoctor(String childId) async {
    final rows = await _c
        .from('messages')
        .select('id')
        .eq('child_id', childId)
        .eq('sender_role', 'doctor')
        .isFilter('read_at', null);
    return rows.length;
  }
}
