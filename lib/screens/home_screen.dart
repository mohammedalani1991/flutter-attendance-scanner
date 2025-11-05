import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import '../providers/student_provider.dart';
import '../services/session_service.dart';
import 'import_students_screen.dart';
import 'scanner_screen.dart';
import 'session_detail_screen.dart';

/// Home dashboard screen - main entry point of the app
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final sessions = ref.watch(sessionsProvider);
    final students = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Scanner'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(activeSessionProvider.notifier).loadActiveSession();
              ref.read(sessionsProvider.notifier).loadSessions();
              ref.read(studentsProvider.notifier).loadStudents();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active session card
            _buildActiveSessionCard(context, ref, activeSession),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(context, ref, activeSession, students),
            const SizedBox(height: 24),

            // Statistics
            _buildStatistics(students, sessions),
            const SizedBox(height: 24),

            // Recent sessions
            _buildRecentSessions(context, ref, sessions),
          ],
        ),
      ),
      floatingActionButton: activeSession.value != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerScreen()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan'),
            )
          : null,
    );
  }

  Widget _buildActiveSessionCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> activeSession,
  ) {
    return activeSession.when(
      data: (session) {
        if (session == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Active Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Start a new session to begin taking attendance.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showStartSessionDialog(context, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Session'),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Session',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  session.courseName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Started: ${_formatDateTime(session.timestampStart)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${session.notes}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SessionDetailScreen(sessionId: session.id!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('View Details'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showEndSessionDialog(context, ref),
                      icon: const Icon(Icons.stop),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> activeSession,
    AsyncValue<dynamic> students,
  ) {
    final studentCount = students.value?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              context: context,
              icon: Icons.upload_file,
              title: 'Import Students',
              subtitle: '$studentCount students',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportStudentsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context: context,
              icon: Icons.qr_code_scanner,
              title: 'Scan QR/Barcode',
              subtitle: activeSession.value != null ? 'Active' : 'No session',
              onTap: activeSession.value != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerScreen(),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: onTap != null ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(
    AsyncValue<dynamic> students,
    AsyncValue<dynamic> sessions,
  ) {
    final studentCount = students.value?.length ?? 0;
    final sessionCount = sessions.value?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.people, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        '$studentCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Students'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.event, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        '$sessionCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Sessions'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSessions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> sessions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        sessions.when(
          data: (sessionList) {
            if (sessionList.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No sessions yet'),
                  ),
                ),
              );
            }

            final recentSessions = sessionList.take(5).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSessions.length,
              itemBuilder: (context, index) {
                final session = recentSessions[index];
                return Dismissible(
                  key: Key('session_${session.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Session'),
                        content: Text(
                          'Are you sure you want to delete "${session.courseName}"?\n\n'
                          'This will permanently delete the session and all its attendance records.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    final sessionService = SessionService();
                    final success = await sessionService.deleteSession(session.id!);

                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Session deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      // Refresh the sessions list
                      ref.read(sessionsProvider.notifier).loadSessions();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete session'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      // Refresh to restore the item
                      ref.read(sessionsProvider.notifier).loadSessions();
                    }
                  },
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        session.isActive ? Icons.circle : Icons.check_circle,
                        color: session.isActive ? Colors.green : Colors.grey,
                      ),
                      title: Text(session.courseName),
                      subtitle: Text(_formatDateTime(session.timestampStart)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SessionDetailScreen(sessionId: session.id!),
                          ),
                        );
                        // Refresh if session was deleted
                        if (result == true) {
                          ref.read(sessionsProvider.notifier).loadSessions();
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  void _showStartSessionDialog(BuildContext context, WidgetRef ref) {
    final courseNameController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                hintText: 'e.g., Computer Science 101',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Mid-term exam',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (courseNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a course name')),
                );
                return;
              }

              final success = await ref
                  .read(activeSessionProvider.notifier)
                  .startSession(
                    courseName: courseNameController.text.trim(),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ref.read(sessionsProvider.notifier).loadSessions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session started successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to start session'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(activeSessionProvider.notifier).endSession();

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ref.read(sessionsProvider.notifier).loadSessions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session ended successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to end session'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
