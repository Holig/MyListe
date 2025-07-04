import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une branche (type de liste, ex: Courses, Séries...)
class Branche {
  final String id;
  final String familleId;
  final String nom;
  final DateTime dateCreation;

  Branche({
    required this.id,
    required this.familleId,
    required this.nom,
    required this.dateCreation,
  });

  factory Branche.fromMap(String id, Map<String, dynamic> data) => Branche(
        id: id,
        familleId: data['familleId'] ?? '',
        nom: data['nom'] ?? '',
        dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'familleId': familleId,
        'nom': nom,
        'dateCreation': Timestamp.fromDate(dateCreation),
      };
} 