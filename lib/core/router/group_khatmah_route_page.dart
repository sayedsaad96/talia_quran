import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/group_khatmah/data/group_khatmah_remote.dart';
import '../../features/group_khatmah/domain/repositories/group_khatmah_repository.dart';
import '../../features/group_khatmah/presentation/cubits/group_khatmah_cubit.dart';
import '../../features/group_khatmah/presentation/pages/group_khatmah_list_page.dart';
import '../identity/record_owner_provider.dart';
import 'app_router.dart';

/// Owns the route's controller and retires it when its audience loses access.
class GroupKhatmahRoutePage extends StatefulWidget {
  const GroupKhatmahRoutePage({
    super.key,
    required this.environment,
    required this.owner,
    required this.repository,
  });
  final GroupKhatmahEnvironment environment;
  final RecordOwnerProvider owner;
  final GroupKhatmahRepository repository;

  @override
  State<GroupKhatmahRoutePage> createState() => _GroupKhatmahRoutePageState();
}

class _GroupKhatmahRoutePageState extends State<GroupKhatmahRoutePage>
    with WidgetsBindingObserver {
  late final GroupKhatmahCubit _cubit;
  late final StreamSubscription<void> _subscription;
  bool _revoked = false;
  Future<void>? _closing;
  final _flowNavigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = GroupKhatmahCubit(
      repository: widget.repository,
      owner: widget.owner,
    );
    _subscription = widget.environment.changes.listen((_) => _checkAccess());
    _checkAccess();
  }

  void _checkAccess() {
    if (_revoked ||
        groupKhatmahRedirect(widget.environment, widget.owner) == null) {
      return;
    }
    _revoked = true;
    unawaited(_closeCubit());
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.khatmahDashboard);
    });
  }

  Future<void> _closeCubit() => _closing ??= _cubit.close();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription.cancel());
    unawaited(_closeCubit());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _revoked
      ? const SizedBox.shrink()
      : NavigatorPopHandler<Object?>(
          onPopWithResult: (result) => _flowNavigator.currentState!.pop(result),
          child: Navigator(
            key: _flowNavigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => GroupKhatmahListPage(
                cubit: _cubit,
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.khatmahDashboard),
              ),
            ),
          ),
        );
}
