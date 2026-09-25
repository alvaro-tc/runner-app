import 'package:meta/meta.dart';

/// Datos privados que el organizador puede asociar a un dorsal.
///
/// Nunca viajan por el socket público: se leen del endpoint protegido de
/// inscripciones y se cruzan localmente con la posición en vivo.
@immutable
class OrganizerParticipant {
  const OrganizerParticipant({
    required this.id,
    required this.name,
    required this.bib,
    this.email,
    this.documentId,
    this.phone,
  });

  factory OrganizerParticipant.fromJson(Map<String, dynamic> json) =>
      OrganizerParticipant(
        id: json['id'] as String,
        name: json['runner'] as String? ?? '',
        bib: json['bibNumber'] as String? ?? '',
        email: json['email'] as String?,
        documentId: json['docId'] as String?,
        phone: json['phone'] as String?,
      );

  final String id;
  final String name;
  final String bib;
  final String? email;
  final String? documentId;
  final String? phone;
}
