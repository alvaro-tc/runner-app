import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/organizer/domain/organizer_participant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La carrera que está ocurriendo ahora. Las futuras y las ya terminadas no se
/// ofrecen como alternativa: el Home del organizador es operativo, no catálogo.
final organizerCurrentMarathonProvider = Provider<AsyncValue<AdminMarathon?>>((
  ref,
) {
  return ref.watch(adminMarathonsProvider).whenData(currentRunningMarathon);
});

AdminMarathon? currentRunningMarathon(List<AdminMarathon> marathons) {
  for (final marathon in marathons) {
    if (marathon.running) return marathon;
  }
  return null;
}

/// Participantes confirmados por dorsal, para enriquecer las posiciones sin
/// exponer nombres en el canal público del mapa.
final organizerParticipantsProvider =
    FutureProvider.family<Map<String, OrganizerParticipant>, String>((
      ref,
      marathonId,
    ) async {
      final rows = await ref
          .watch(adminApiProvider)
          .confirmedRegistrations(marathonId);
      final participants = <String, OrganizerParticipant>{};
      for (final row in rows) {
        final participant = OrganizerParticipant.fromJson(row);
        if (participant.bib.isNotEmpty) {
          participants[participant.bib] = participant;
        }
      }
      return participants;
    });
