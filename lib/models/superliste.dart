import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une superliste (type de listes)
class Superliste {
  final String id;
  final String familleId;
  final String nom;
  final DateTime dateCreation;

  Superliste({
    required this.id,
    required this.familleId,
    required this.nom,
    required this.dateCreation,
  });

  factory Superliste.fromMap(String id, Map<String, dynamic> data) => Superliste(
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