import 'package:cloud_firestore/cloud_firestore.dart';
import 'tag.dart';

/// Modèle représentant une liste (ex: Semaine 25)
class Liste {
  final String id;
  final String superlisteId;
  final String titre;
  final DateTime date;
  final bool fermee;
  // On retire le champ elements

  Liste({
    required this.id,
    required this.superlisteId,
    required this.titre,
    required this.date,
    required this.fermee,
  });

  factory Liste.fromMap(String id, Map<String, dynamic> data) => Liste(
        id: id,
        superlisteId: data['superlisteId'] ?? '',
        titre: data['titre'] ?? '',
        date: (data['date'] as Timestamp).toDate(),
        fermee: data['fermee'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'superlisteId': superlisteId,
        'titre': titre,
        'date': Timestamp.fromDate(date),
        'fermee': fermee,
      };

  /// Nouvelle méthode pour charger les éléments depuis la sous-collection
  Future<List<Tag>> fetchElements(String familleId) async {
    final itemsSnap = await FirebaseFirestore.instance
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(id)
        .collection('items')
        .get();
    return itemsSnap.docs.map((d) => Tag.fromMap(d.data())).toList();
  }

  /// Version stream pour l’UI réactive
  Stream<List<Tag>> elementsStream(String familleId) {
    return FirebaseFirestore.instance
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(id)
        .collection('items')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Tag.fromMap(d.data())).toList());
  }
} 