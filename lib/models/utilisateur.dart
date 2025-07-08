import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un utilisateur
class Utilisateur {
  final String id;
  final String email;
  final String? nom;
  final String? photoUrl;
  final List<String> famillesIds;
  final String familleActiveId;
  final DateTime dateInscription;
  // Ancien champ pour compatibilité migration
  final String? familleId;

  Utilisateur({
    required this.id,
    required this.email,
    this.nom,
    this.photoUrl,
    required this.famillesIds,
    required this.familleActiveId,
    required this.dateInscription,
    this.familleId,
  });

  factory Utilisateur.fromMap(String id, Map<String, dynamic> data) {
    return Utilisateur(
      id: id,
      email: data['email'] ?? '',
      nom: data['nom'],
      photoUrl: data['photoUrl'],
      famillesIds: (data['famillesIds'] as List?)?.map((e) => e.toString()).toList() ?? (data['familleId'] != null && data['familleId'] != '' ? [data['familleId']] : []),
      familleActiveId: data['familleActiveId'] ?? data['familleId'] ?? '',
      dateInscription: (data['dateInscription'] as Timestamp?)?.toDate() ?? DateTime.now(),
      familleId: data['familleId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nom': nom,
      'photoUrl': photoUrl,
      'famillesIds': famillesIds,
      'familleActiveId': familleActiveId,
      'dateInscription': dateInscription,
      'familleId': familleId, // Pour compatibilité migration
    };
  }
} 