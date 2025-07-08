import 'package:cloud_firestore/cloud_firestore.dart';
import 'tag.dart';

/// Modèle représentant une liste (ex: Semaine 25)
class Liste {
  final String id;
  final String superlisteId;
  final String titre;
  final DateTime date;
  final bool fermee;
  final List<Tag> elements;

  Liste({
    required this.id,
    required this.superlisteId,
    required this.titre,
    required this.date,
    required this.fermee,
    required this.elements,
  });

  factory Liste.fromMap(String id, Map<String, dynamic> data) => Liste(
        id: id,
        superlisteId: data['superlisteId'] ?? '',
        titre: data['titre'] ?? '',
        date: (data['date'] as Timestamp).toDate(),
        fermee: data['fermee'] ?? false,
        elements: (data['elements'] as List<dynamic>? ?? [])
            .map((e) => Tag.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'superlisteId': superlisteId,
        'titre': titre,
        'date': Timestamp.fromDate(date),
        'fermee': fermee,
        'elements': elements.map((e) => e.toMap()).toList(),
      };
} 