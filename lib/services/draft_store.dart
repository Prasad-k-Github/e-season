// lib/services/draft_store.dart

import 'package:e_season/models/registration_draft.dart';

/// A draft read back from storage, plus the last step the user completed.
class SavedRegistration {
  final RegistrationDraft draft;
  final RegStep step;
  const SavedRegistration(this.draft, this.step);
}

/// Where the half-finished registration lives between steps (and app restarts).
///
/// Implementations must never store the password or the email proof; see
/// [RegistrationDraft.toJson].
abstract class DraftStore {
  Future<SavedRegistration?> load();

  /// [step] is the page the user just completed.
  Future<void> save(RegistrationDraft draft, RegStep step);

  /// Copies a freshly picked image somewhere that survives the system clearing
  /// its cache, and returns the new path. Safe to call twice on the same file.
  Future<String> keepImage(String sourcePath);

  /// Deletes the saved draft and every image kept for it.
  Future<void> clear();
}

/// In-memory store for tests and previews; nothing survives a restart.
class MemoryDraftStore implements DraftStore {
  Map<String, dynamic>? _json;
  RegStep? _step;

  bool get hasDraft => _json != null;

  @override
  Future<SavedRegistration?> load() async {
    final json = _json;
    final step = _step;
    if (json == null || step == null) return null;
    return SavedRegistration(RegistrationDraft.fromJson(json), step);
  }

  @override
  Future<void> save(RegistrationDraft draft, RegStep step) async {
    _json = draft.toJson();
    _step = step;
  }

  @override
  Future<String> keepImage(String sourcePath) async => sourcePath;

  @override
  Future<void> clear() async {
    _json = null;
    _step = null;
  }
}
