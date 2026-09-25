import 'dart:async';

import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:camrun/features/organizer/domain/organizer_participant.dart';
import 'package:camrun/features/organizer/presentation/providers/organizer_providers.dart';
import 'package:camrun/l10n/l10n_labels.dart';
import 'package:camrun/shared/widgets/atoms/app_indicators.dart';
import 'package:camrun/shared/widgets/atoms/skeleton.dart';
import 'package:camrun/shared/widgets/molecules/states.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puesto de observación del organizador.
///
/// Vive en un árbol propio y no contiene ninguna acción que cambie la carrera.
/// El guard del router completa esa frontera expulsando a un organizer que
/// escriba una URL de `/admin` a mano.
class OrganizerHomePage extends ConsumerWidget {
  const OrganizerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(organizerCurrentMarathonProvider);
    final t = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.organizerLiveTitle),
        actions: const [
          NotificationBell(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: current.when(
        skipLoadingOnReload: true,
        loading: _LoadingView.new,
        error: (error, _) => ErrorStateView(
          message: error is Failure ? error.localized(t) : t.adminLoadFailed,
          onRetry: () => ref.invalidate(adminMarathonsProvider),
        ),
        data: (marathon) => marathon == null
            ? EmptyState(
                key: const Key('organizer-no-current-marathon'),
                icon: Icons.sports_score_outlined,
                title: t.organizerNoCurrentTitle,
                message: t.organizerNoCurrentBody,
                actionLabel: t.commonRetry,
                onAction: () => ref.invalidate(adminMarathonsProvider),
              )
            : _CurrentRace(marathon: marathon),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.screenH),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(width: double.infinity, height: 86),
        SizedBox(height: AppSpacing.base),
        Expanded(
          child: Skeleton(width: double.infinity, height: double.infinity),
        ),
        SizedBox(height: AppSpacing.base),
        Skeleton(width: double.infinity, height: 72),
      ],
    ),
  );
}

class _CurrentRace extends ConsumerWidget {
  const _CurrentRace({required this.marathon});

  final AdminMarathon marathon;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(adminMarathonsProvider)
      ..invalidate(adminMarathonProvider(marathon.id))
      ..invalidate(organizerParticipantsProvider(marathon.id));
    await ref.read(liveBoardProvider(marathon.id).notifier).reload();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminMarathonProvider(marathon.id));
    final participants = ref.watch(organizerParticipantsProvider(marathon.id));
    final board = ref.watch(liveBoardProvider(marathon.id));
    final t = context.l10n;

    if (board.failure case final failure?) {
      return ErrorStateView(
        message: failure.localized(t),
        onRetry: () => unawaited(_refresh(ref)),
      );
    }
    if (board.loading) return const _LoadingView();
    if (board.finishedAt != null) {
      return EmptyState(
        key: const Key('organizer-no-current-marathon'),
        icon: Icons.sports_score_outlined,
        title: t.organizerNoCurrentTitle,
        message: t.organizerNoCurrentBody,
        actionLabel: t.commonRetry,
        onAction: () => unawaited(_refresh(ref)),
      );
    }

    return detail.when(
      skipLoadingOnReload: true,
      loading: _LoadingView.new,
      error: (error, _) => ErrorStateView(
        message: error is Failure ? error.localized(t) : t.adminLoadFailed,
        onRetry: () => unawaited(_refresh(ref)),
      ),
      data: (fullMarathon) => participants.when(
        skipLoadingOnReload: true,
        loading: _LoadingView.new,
        error: (error, _) => ErrorStateView(
          message: error is Failure ? error.localized(t) : t.adminLoadFailed,
          onRetry: () => unawaited(_refresh(ref)),
        ),
        data: (byBib) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: _Dashboard(
            marathon: fullMarathon,
            board: board,
            participants: byBib,
          ),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.marathon,
    required this.board,
    required this.participants,
  });

  final AdminMarathon marathon;
  final LiveBoard board;
  final Map<String, OrganizerParticipant> participants;

  List<LivePosition> get _positions {
    final rows = board.runners.values.toList()
      ..sort((a, b) => (a.bib ?? '').compareTo(b.bib ?? ''));
    return rows;
  }

  void _openRunner(BuildContext context, LivePosition position) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RunnerDetail(
        marathonId: marathon.id,
        initial: position,
        participant: participants[position.bib],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final positions = _positions;
    final runningCount = positions
        .where((p) => !board.finishedBibs.contains(p.key))
        .length;

    return ListView(
      key: const Key('organizer-live-dashboard'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.base,
        AppSpacing.screenH,
        AppSpacing.xxl,
      ),
      children: [
        _MarathonHeader(marathon: marathon, runningCount: runningCount),
        const SizedBox(height: AppSpacing.base),
        SizedBox(
          height: 310,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: RouteMapView(
              route: const [],
              guideRoute: marathon.route,
              markerEveryKm: 5,
              pins: [
                for (final position in positions)
                  MapPin(
                    lat: position.lat,
                    lng: position.lng,
                    size: 38,
                    child: _RunnerPin(
                      bib: position.bib,
                      finished: board.finishedBibs.contains(position.key),
                      onTap: () => _openRunner(context, position),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          t.organizerParticipantsOnCourse(runningCount),
          style: context.text.headingMd,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (positions.isEmpty)
          _NoRunners()
        else
          for (final position in positions)
            _RunnerTile(
              position: position,
              participant: participants[position.bib],
              finished: board.finishedBibs.contains(position.key),
              onTap: () => _openRunner(context, position),
            ),
      ],
    );
  }
}

class _MarathonHeader extends StatelessWidget {
  const _MarathonHeader({required this.marathon, required this.runningCount});

  final AdminMarathon marathon;
  final int runningCount;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.successBg,
              ),
              child: Icon(Icons.directions_run_rounded, color: c.success),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.organizerCurrentMarathon, style: context.text.labelSm),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    marathon.name,
                    style: context.text.titleMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    marathon.city,
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            AppBadge(
              label: t.adminRunnersOnCourse(runningCount),
              tone: AppTone.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _RunnerPin extends StatelessWidget {
  const _RunnerPin({
    required this.bib,
    required this.finished,
    required this.onTap,
  });

  final String? bib;
  final bool finished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = bib?.isNotEmpty == true ? bib! : '?';
    return Semantics(
      button: true,
      label: label,
      child: Material(
        shape: const CircleBorder(),
        color: finished ? c.success : c.primary,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              label.substring(label.length > 3 ? label.length - 3 : 0),
              style: context.text.labelSm.copyWith(
                color: c.onPrimary,
                fontSize: 9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoRunners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    return Container(
      key: const Key('organizer-no-runners'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.location_searching_rounded, color: c.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.organizerNoRunnersTitle,
            textAlign: TextAlign.center,
            style: context.text.titleMd,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.organizerNoRunnersBody,
            textAlign: TextAlign.center,
            style: context.text.bodySm.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RunnerTile extends StatelessWidget {
  const _RunnerTile({
    required this.position,
    required this.participant,
    required this.finished,
    required this.onTap,
  });

  final LivePosition position;
  final OrganizerParticipant? participant;
  final bool finished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final c = context.colors;
    final name = participant?.name.isNotEmpty == true
        ? participant!.name
        : t.organizerRunnerUnknown;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        key: ValueKey('organizer-runner-${position.key}'),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: finished ? c.successBg : c.primaryContainer,
          foregroundColor: finished ? c.success : c.primary,
          child: Text(position.bib ?? '?'),
        ),
        title: Text(name),
        subtitle: Text(Fmt.distance(position.distanceMeters / 1000)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBadge(
              label: finished
                  ? t.organizerRunnerFinished
                  : t.organizerRunnerRunning,
              tone: finished ? AppTone.success : AppTone.info,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _RunnerDetail extends ConsumerWidget {
  const _RunnerDetail({
    required this.marathonId,
    required this.initial,
    required this.participant,
  });

  final String marathonId;
  final LivePosition initial;
  final OrganizerParticipant? participant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(liveBoardProvider(marathonId));
    final position = board.runners[initial.key] ?? initial;
    final finished = board.finishedBibs.contains(position.key);
    final t = context.l10n;
    final c = context.colors;
    final name = participant?.name.isNotEmpty == true
        ? participant!.name
        : t.organizerRunnerUnknown;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.organizerRunnerDetailTitle, style: context.text.headingMd),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: c.primaryContainer,
                  foregroundColor: c.primary,
                  child: Text(position.bib ?? '?'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.text.headingMd),
                      const SizedBox(height: AppSpacing.xs),
                      AppBadge(
                        label: finished
                            ? t.organizerRunnerFinished
                            : t.organizerRunnerRunning,
                        tone: finished ? AppTone.success : AppTone.info,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: t.organizerRunnerLocation,
              value: t.organizerRunnerCoordinates(
                position.lat.toStringAsFixed(5),
                position.lng.toStringAsFixed(5),
              ),
            ),
            _DetailRow(
              icon: Icons.route_outlined,
              label: t.organizerRunnerDistance,
              value: Fmt.distance(position.distanceMeters / 1000),
            ),
            _DetailRow(
              icon: Icons.loop_rounded,
              label: t.organizerRunnerLap,
              value: '${position.lap}',
            ),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: t.organizerRunnerLastUpdate,
              value: Fmt.timeOfDay(position.at.toLocal()),
            ),
            if (participant?.phone case final phone? when phone.isNotEmpty)
              _DetailRow(
                icon: Icons.phone_outlined,
                label: t.organizerRunnerContact,
                value: phone,
              )
            else if (participant?.email case final email? when email.isNotEmpty)
              _DetailRow(
                icon: Icons.email_outlined,
                label: t.organizerRunnerContact,
                value: email,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: c.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSm.copyWith(color: c.textSecondary),
                ),
                Text(value, style: context.text.bodyMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
