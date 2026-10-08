import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../../tasks/models/task.dart';
import '../../tasks/viewmodels/tasks_view_model.dart';
import '../viewmodels/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  GoRouter? _router;
  bool _wasHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_router == router) return;
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = router;
    _wasHome = _isHomeRoute(router);
    router.routerDelegate.addListener(_onRouteChanged);
  }

  bool _isHomeRoute(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path == '/home';

  void _onRouteChanged() {
    final router = _router;
    if (router == null) return;
    final isHome = _isHomeRoute(router);
    if (isHome && !_wasHome) {
      ref.read(homeViewModelProvider.notifier).loadHomeData();
    }
    _wasHome = isHome;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _router != null && _isHomeRoute(_router!)) {
      ref.read(homeViewModelProvider.notifier).loadHomeData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final homeState = ref.watch(homeViewModelProvider);
    final userName = authState.user?.name ?? 'Carlos';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: context.palette.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.palette.primaryText,
          backgroundColor: context.palette.surface,
          onRefresh: () =>
              ref.read(homeViewModelProvider.notifier).loadHomeData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Greeting, Date, Avatar, AI Sparkle Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $userName',
                          style: TextStyle(
                            color: context.palette.primaryText,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatFull(DateTime.now()),
                          style: TextStyle(
                            color: context.palette.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // AI Sparkle action button matching Penpot
                        GestureDetector(
                          onTap: () => context.push('/tasks/ai'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.palette.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '✦',
                                style: TextStyle(
                                  color: context.palette.onAccent,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Avatar
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.palette.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userInitial,
                                style: TextStyle(
                                  color: context.palette.onAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // AI Summary Card (Tarjetas IA from Penpot)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.palette.accentContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.track,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Resumen con IA',
                              style: TextStyle(
                                color: context.palette.onAccentContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (homeState.isSummaryLoading) ...[
                              const SizedBox(width: 7),
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: context.palette.onAccentContainer,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        homeState.aiSummary,
                        style: TextStyle(
                          color: context.palette.onAccentContainer,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Stat Boxes (Pendientes, Recordatorios, Eventos hoy)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context: context,
                        count: '${homeState.pendingTasksCount}',
                        label: 'Pendientes',
                        numberColor: context.palette.primaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatBox(
                        context: context,
                        count: '${homeState.remindersCount}',
                        label: 'Recordatorios',
                        numberColor: context.palette.primaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatBox(
                        context: context,
                        count: '${homeState.upcomingEventsCount}',
                        label: 'Eventos hoy',
                        numberColor: context.palette.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Tareas de hoy Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tareas de hoy',
                      style: TextStyle(
                        color: context.palette.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/tasks'),
                      child: Text(
                        'Ver todas',
                        style: TextStyle(
                          color: context.palette.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (homeState.errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.warningContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: context.palette.onWarningContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            homeState.errorMessage!,
                            style: TextStyle(
                              color: context.palette.onWarningContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (homeState.isLoading) ...[
                  const LoadingView(message: 'Cargando resumen...'),
                ] else if (homeState.pendingTasks.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Center(
                      child: Text(
                        'No hay tareas pendientes para hoy',
                        style: TextStyle(
                          color: context.palette.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ...homeState.pendingTasks
                      .take(3)
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTaskCard(context, ref, task),
                        ),
                      ),
                ],
                const SizedBox(height: 24),

                // Próximo evento Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Próximo evento',
                      style: TextStyle(
                        color: context.palette.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/events'),
                      child: Text(
                        'Ver agenda',
                        style: TextStyle(
                          color: context.palette.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (homeState.isLoading && homeState.upcomingEvents.isEmpty)
                  const LoadingView(message: 'Cargando eventos...')
                else if (homeState.upcomingEvents.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Center(
                      child: Text(
                        'No hay próximos eventos',
                        style: TextStyle(
                          color: context.palette.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...homeState.upcomingEvents
                      .take(3)
                      .map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.palette.border,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      color: context.palette.track,
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => context.push(
                                          '/events/${event.id}',
                                          extra: event,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.title,
                                                style: TextStyle(
                                                  color: context.palette.primaryText,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${AppDateUtils.formatShort(event.startDate)}${event.location?.isNotEmpty == true ? ' · ${event.location}' : ''}',
                                                style: TextStyle(
                                                  color: context.palette.secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (event
                                                      .description
                                                      ?.isNotEmpty ==
                                                  true) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  event.description!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: context.palette.secondaryText,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required BuildContext context,
    required String count,
    required String label,
    required Color numberColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              color: numberColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: context.palette.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Task task) {
    String priorityText = 'Media';
    Color chipBg = context.palette.surfaceSecondary;
    Color chipFg = context.palette.secondaryText;

    if (task.priority == TaskPriority.high) {
      priorityText = 'Alta';
      chipBg = context.palette.surfaceSecondary;
      chipFg = context.palette.primaryText;
    } else if (task.priority == TaskPriority.low) {
      priorityText = 'Baja';
      chipBg = context.palette.surfaceSecondary;
      chipFg = context.palette.secondaryText;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/tasks/${task.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ref
                        .read(tasksViewModelProvider.notifier)
                        .toggleTaskStatus(task);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? context.palette.accent
                            : context.palette.placeholder,
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? context.palette.accent
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? Center(
                            child: Icon(
                              PhosphorIconsBold.check,
                              size: 12,
                              color: context.palette.onAccent,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted
                              ? context.palette.secondaryText
                              : context.palette.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.dueDate != null
                            ? AppDateUtils.formatShort(task.dueDate!)
                            : 'Hoy',
                        style: TextStyle(
                          color: context.palette.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(
                      color: chipFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
