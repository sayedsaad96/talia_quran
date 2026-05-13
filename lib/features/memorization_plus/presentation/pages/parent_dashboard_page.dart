import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/parent_dashboard_cubit.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key, required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ParentDashboardCubit>()..load(surahId: surahId),
      child: _ParentDashboardView(surahId: surahId),
    );
  }
}

class _ParentDashboardView extends StatefulWidget {
  const _ParentDashboardView({required this.surahId});
  final int surahId;

  @override
  State<_ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<_ParentDashboardView> {
  final _pinController = TextEditingController();
  final _rewardController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('لوحة ولي الأمر', style: AppTypography.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: BlocConsumer<ParentDashboardCubit, ParentDashboardState>(
        listener: (context, state) {
          final message = switch (state) {
            ParentDashboardLocked(:final message) => message,
            ParentDashboardLoaded(:final message) => message,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          if (state is ParentDashboardLoading ||
              state is ParentDashboardInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is ParentDashboardError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<ParentDashboardCubit>().load(
                surahId: widget.surahId,
              ),
            );
          }
          if (state is ParentDashboardNeedsPin) {
            return _PinGate(
              title: 'أنشئ رمز ولي الأمر',
              buttonText: 'حفظ الرمز',
              controller: _pinController,
              onSubmit: (pin) => context.read<ParentDashboardCubit>().setPin(
                pin,
                surahId: widget.surahId,
              ),
            );
          }
          if (state is ParentDashboardLocked) {
            return _PinGate(
              title: 'أدخل رمز ولي الأمر',
              buttonText: 'دخول',
              controller: _pinController,
              onSubmit: (pin) => context.read<ParentDashboardCubit>().unlock(
                pin,
                surahId: widget.surahId,
              ),
              onReset: () => context.read<ParentDashboardCubit>().resetAccess(
                surahId: widget.surahId,
              ),
            );
          }
          if (state is ParentDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<ParentDashboardCubit>().refresh(
                surahId: widget.surahId,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  120,
                ),
                children: [
                  _SummaryCard(dashboard: state.dashboard),
                  const SizedBox(height: AppSpacing.lg),
                  _ReminderCard(settings: state.dashboard.settings),
                  const SizedBox(height: AppSpacing.lg),
                  _RemoteToolsCard(
                    children: state.remoteChildren,
                    onScan: () => _openScanner(context),
                    onManual: () => _showManualTokenDialog(context),
                    onAddReward: (childId) =>
                        _showRemoteRewardDialog(context, childId),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _RewardsCard(
                    rewards: state.dashboard.rewards,
                    controller: _rewardController,
                    onAdd: () {
                      context.read<ParentDashboardCubit>().addReward(
                        _rewardController.text,
                      );
                      _rewardController.clear();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _LogsCard(logs: state.dashboard.logs),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final token = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _QrScannerPage()));
    if (token != null && context.mounted) {
      await context.read<ParentDashboardCubit>().acceptRemoteToken(
        token,
        surahId: widget.surahId,
      );
    }
  }

  Future<void> _showManualTokenDialog(BuildContext context) async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إدخال رمز الربط'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'talia-kids-link:...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ربط'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (token != null && token.isNotEmpty && context.mounted) {
      await context.read<ParentDashboardCubit>().acceptRemoteToken(
        token,
        surahId: widget.surahId,
      );
    }
  }

  Future<void> _showRemoteRewardDialog(
    BuildContext context,
    String childId,
  ) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مكافأة للطفل'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'مثال: نزهة قصيرة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty && context.mounted) {
      await context.read<ParentDashboardCubit>().addRemoteReward(
        childId,
        title,
      );
    }
  }
}

class _PinGate extends StatelessWidget {
  const _PinGate({
    required this.title,
    required this.buttonText,
    required this.controller,
    required this.onSubmit,
    this.onReset,
  });

  final String title;
  final String buttonText;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 54, color: Color(0xFF2D8E4C)),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(counterText: ''),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => onSubmit(controller.text.trim()),
                child: Text(buttonText),
              ),
            ),
            if (onReset != null)
              TextButton(
                onPressed: onReset,
                child: const Text('نسيت الرمز؟ إعادة ضبط محلية'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.dashboard});
  final ParentDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final p = dashboard.progress;
    return _Panel(
      title: 'ملخص الطفل',
      child: Column(
        children: [
          Row(
            children: [
              _Metric(label: 'نقاط', value: '${p.totalPoints}'),
              _Metric(label: 'نجوم', value: '${p.starsEarned}'),
              _Metric(
                label: 'جلسات الأسبوع',
                value: '${dashboard.weeklyCompletedSessions}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value:
                (dashboard.weeklyCompletedSessions /
                        dashboard.settings.weeklyGoalSessions)
                    .clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFF2D8E4C).withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2D8E4C)),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.settings});
  final ParentSettings settings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'تذكير الطفل',
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: settings.reminderEnabled,
        title: const Text('تذكير يومي الساعة 6:30 مساءً'),
        subtitle: const Text('يمكن تغيير الوقت لاحقًا من إعدادات ولي الأمر'),
        onChanged: (value) =>
            context.read<ParentDashboardCubit>().updateReminder(
              enabled: value,
              hour: settings.reminderHour,
              minute: settings.reminderMinute,
            ),
      ),
    );
  }
}

class _RemoteToolsCard extends StatelessWidget {
  const _RemoteToolsCard({
    required this.children,
    required this.onScan,
    required this.onManual,
    required this.onAddReward,
  });

  final List<RemoteChildSummary> children;
  final VoidCallback onScan;
  final VoidCallback onManual;
  final ValueChanged<String> onAddReward;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'المتابعة عن بعد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('مسح QR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: onManual,
                  child: const Text('إدخال يدوي'),
                ),
              ),
            ],
          ),
          if (children.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('لا يوجد طفل مرتبط عن بعد حتى الآن.'),
            )
          else
            ...children.map(
              (child) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.child_care_rounded),
                ),
                title: Text(child.displayName),
                subtitle: Text(
                  '${child.progress.ayahsCompleted} آية • ${child.progress.totalPoints} نقطة',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.card_giftcard_rounded),
                  onPressed: () => onAddReward(child.childUserId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({
    required this.rewards,
    required this.controller,
    required this.onAdd,
  });

  final List<ParentReward> rewards;
  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'مكافآت ولي الأمر',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'مثال: وقت لعب إضافي',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: onAdd, child: const Text('إضافة')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rewards.isEmpty)
            const Text('أضف مكافآت تظهر للطفل عند تحقيق هدفه الأسبوعي.')
          else
            ...rewards.map(
              (reward) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  reward.status == ParentRewardStatus.locked
                      ? Icons.lock_rounded
                      : Icons.emoji_events_rounded,
                ),
                title: Text(reward.title),
                subtitle: Text(_rewardStatusLabel(reward.status)),
              ),
            ),
        ],
      ),
    );
  }

  String _rewardStatusLabel(ParentRewardStatus status) => switch (status) {
    ParentRewardStatus.locked => 'مقفلة',
    ParentRewardStatus.unlocked => 'مفتوحة',
    ParentRewardStatus.claimed => 'تم استلامها',
  };
}

class _LogsCard extends StatelessWidget {
  const _LogsCard({required this.logs});
  final List<KidsSessionLog> logs;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'آخر الجلسات',
      child: logs.isEmpty
          ? const Text('لا توجد جلسات أطفال بعد.')
          : Column(
              children: logs.take(8).map((log) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2D8E4C),
                  ),
                  title: Text('سورة ${log.surahId} • آية ${log.ayahNumber}'),
                  subtitle: Text(
                    '${log.repeatsCompleted} تكرارات • ${log.pointsEarned} نقطة',
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineSmall),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(fontFamily: 'Amiri'),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح رمز الطفل')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          String? value;
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              value = barcode.rawValue;
              break;
            }
          }
          if (value == null || value.isEmpty) return;
          _done = true;
          Navigator.pop(context, value);
        },
      ),
    );
  }
}
