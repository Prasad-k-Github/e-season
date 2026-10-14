// lib/services/secure_draft_store.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'package:e_season/models/registration_draft.dart';
import 'package:e_season/services/draft_store.dart';

/// Keeps the draft's text fields in the platform's encrypted storage
/// (Keystore on Android, Keychain on iOS) and copies picked images into the
/// app's private folder. Nothing here is ever logged.
class SecureDraftStore implements DraftStore {
  static const _key = 'registration_draft_v1';

  final FlutterSecureStorage _storage;

  SecureDraftStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<Directory> _imageDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}registration_drafts');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<SavedRegistration?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final step = RegStep.values.firstWhere((s) => s.name == map['step']);
      final draft =
          RegistrationDraft.fromJson(map['draft'] as Map<String, dynamic>);
      // An image the OS has since deleted counts as not picked.
      if (!await _exists(draft.profilePhotoPath)) draft.profilePhotoPath = null;
      if (!await _exists(draft.nicFrontPath)) draft.nicFrontPath = null;
      if (!await _exists(draft.nicBackPath)) draft.nicBackPath = null;
      return SavedRegistration(draft, step);
    } catch (_) {
      await clear(); // unreadable or from an older format: start fresh
      return null;
    }
  }

  @override
  Future<void> save(RegistrationDraft draft, RegStep step) => _storage.write(
        key: _key,
        value: jsonEncode({'step': step.name, 'draft': draft.toJson()}),
      );

  @override
  Future<String> keepImage(String sourcePath) async {
    final dir = await _imageDir();
    if (sourcePath.startsWith(dir.path)) return sourcePath;
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot > sourcePath.lastIndexOf(Platform.pathSeparator) && dot != -1
        ? sourcePath.substring(dot)
        : '.jpg';
    final target =
        '${dir.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(sourcePath).copy(target);
    return target;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}${Platform.pathSeparator}registration_drafts');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Best effort: the draft itself is already gone.
    }
  }

  static Future<bool> _exists(String? path) async =>
      path != null && await File(path).exists();
}
