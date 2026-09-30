import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/splash_screen.dart';
import '../features/events/models/event.dart';
import '../features/events/views/ai_event_screen.dart';
import '../features/events/views/event_detail_screen.dart';
import '../features/events/views/event_form_screen.dart';
import '../features/events/views/events_screen.dart';
import '../features/home/views/home_screen.dart';
import '../features/notes/models/note.dart';
import '../features/notes/views/ai_note_screen.dart';
import '../features/notes/views/note_detail_screen.dart';
import '../features/notes/views/note_form_screen.dart';
import '../features/notes/views/notes_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/tasks/models/task.dart';
import '../features/tasks/views/ai_task_screen.dart';
import '../features/tasks/views/task_detail_screen.dart';
import '../features/tasks/views/task_form_screen.dart';
import '../features/tasks/views/tasks_screen.dart';
import 'theme.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Bottom Navigation Shell for 4 Main Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Tasks Subroutes
      GoRoute(
        path: '/tasks/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TaskFormScreen(),
      ),
      GoRoute(
        path: '/tasks/ai',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AITaskScreen(),
      ),
      GoRoute(
        path: '/tasks/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: id);
        },
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final task = state.extra as Task?;
          return TaskFormScreen(taskToEdit: task);
        },
      ),

      // Notes Subroutes
      GoRoute(
        path: '/notes/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NoteFormScreen(),
      ),
      GoRoute(
        path: '/notes/ai',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AINoteScreen(),
      ),
      GoRoute(
        path: '/notes/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final note = state.extra as Note?;
          return NoteDetailScreen(noteId: id, initialNote: note);
        },
      ),
      GoRoute(
        path: '/notes/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final note = state.extra as Note?;
          return NoteFormScreen(noteToEdit: note);
        },
      ),

      // Events Subroutes
      GoRoute(
        path: '/events/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EventFormScreen(),
      ),
      GoRoute(
        path: '/events/ai',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AIEventScreen(),
      ),
      GoRoute(
        path: '/events/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final event = state.extra as Event?;
          return EventDetailScreen(eventId: id, initialEvent: event);
        },
      ),
      GoRoute(
        path: '/events/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final event = state.extra as Event?;
          return EventFormScreen(eventToEdit: event);
        },
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.primarySurface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: PhosphorIconsRegular.house,
                  activeIcon: PhosphorIconsFill.house,
                  label: 'Inicio',
                ),
                _buildNavItem(
                  index: 1,
                  icon: PhosphorIconsRegular.checkCircle,
                  activeIcon: PhosphorIconsFill.checkCircle,
                  label: 'Tareas',
                ),
                _buildNavItem(
                  index: 2,
                  icon: PhosphorIconsRegular.note,
                  activeIcon: PhosphorIconsFill.note,
                  label: 'Notas',
                ),
                _buildNavItem(
                  index: 3,
                  icon: PhosphorIconsRegular.calendarBlank,
                  activeIcon: PhosphorIconsFill.calendarBlank,
                  label: 'Eventos',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.white : AppColors.secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.secondaryText,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
