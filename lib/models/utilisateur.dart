import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un utilisateur
class Utilisateur {
  final String id;
  final String email;
  final String? nom;
  final String? photoUrl;
  final String familleId;
  final DateTime dateInscription;

  Utilisateur({
    required this.id,
    required this.email,
    this.nom,
    this.photoUrl,
    required this.familleId,
    required this.dateInscription,
  });

  factory Utilisateur.fromMap(String id, Map<String, dynamic> data) => Utilisateur(
        id: id,
        email: data['email'] ?? '',
        nom: data['nom'],
        photoUrl: data['photoUrl'],
        familleId: data['familleId'] ?? '',
        dateInscription: (data['dateInscription'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'nom': nom,
        'photoUrl': photoUrl,
        'familleId': familleId,
        'dateInscription': Timestamp.fromDate(dateInscription),
      };
} 