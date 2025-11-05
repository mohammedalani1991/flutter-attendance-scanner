import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/attendance_record.dart';
import '../services/session_service.dart';

/// Provider for session service
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

/// Provider for active session
final activeSessionProvider = StateNotifierProvider<ActiveSessionNotifier, AsyncValue<Session?>>((ref) {
  return ActiveSessionNotifier(ref.read(sessionServiceProvider));
});

/// Provider for all sessions list
final sessionsProvider = StateNotifierProvider<SessionsNotifier, AsyncValue<List<Session>>>((ref) {
  return SessionsNotifier(ref.read(sessionServiceProvider));
});

/// Provider for attendance records of current session
final attendanceRecordsProvider = StateNotifierProvider<AttendanceRecordsNotifier, AsyncValue<List<AttendanceRecord>>>((ref) {
  final activeSession = ref.watch(activeSessionProvider);
  return AttendanceRecordsNotifier(
    ref.read(sessionServiceProvider),
    activeSession.value,
  );
});

/// Notifier for managing active session state
class ActiveSessionNotifier extends StateNotifier<AsyncValue<Session?>> {
  final SessionService _sessionService;

  ActiveSessionNotifier(this._sessionService) : super(const AsyncValue.loading()) {
    loadActiveSession();
  }

  /// Load active session
  Future<void> loadActiveSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _sessionService.getActiveSession();
      state = AsyncValue.data(session);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Start a new session
  Future<bool> startSession({
    required String courseName,
    String? notes,
  }) async {
    try {
      final result = await _sessionService.startSession(
        courseName: courseName,
        notes: notes,
      );
      if (result.success) {
        state = AsyncValue.data(result.session);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// End current session
  Future<bool> endSession() async {
    final currentSession = state.value;
    if (currentSession == null) return false;

    try {
      final result = await _sessionService.endSession(currentSession.id!);
      if (result.success) {
        state = const AsyncValue.data(null);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Notifier for managing sessions list
class SessionsNotifier extends StateNotifier<AsyncValue<List<Session>>> {
  final SessionService _sessionService;

  SessionsNotifier(this._sessionService) : super(const AsyncValue.loading()) {
    loadSessions();
  }

  /// Load all sessions
  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _sessionService.getAllSessions();
      state = AsyncValue.data(sessions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Delete a session
  Future<bool> deleteSession(int sessionId) async {
    try {
      final success = await _sessionService.deleteSession(sessionId);
      if (success) {
        await loadSessions();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Export session attendance
  Future<String?> exportSession(int sessionId) async {
    try {
      return await _sessionService.exportSessionAttendance(sessionId);
    } catch (e) {
      return null;
    }
  }
}

/// Notifier for managing attendance records
class AttendanceRecordsNotifier extends StateNotifier<AsyncValue<List<AttendanceRecord>>> {
  final SessionService _sessionService;
  final Session? _currentSession;

  AttendanceRecordsNotifier(this._sessionService, this._currentSession)
      : super(const AsyncValue.loading()) {
    if (_currentSession != null) {
      loadAttendanceRecords();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  /// Load attendance records for current session
  Future<void> loadAttendanceRecords() async {
    if (_currentSession == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final records = await _sessionService.getAttendanceRecords(_currentSession.id!);
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh attendance records (call after new scan)
  Future<void> refresh() async {
    await loadAttendanceRecords();
  }
}
