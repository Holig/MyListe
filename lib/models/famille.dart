import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une famille (groupe d'utilisateurs)
class Famille {
  final String id;
  final String nom;
  final List<String> membresIds;
  final List<String> adminIds;
  final String codeInvitation;
  final DateTime dateCreation;

  Famille({
    required this.id,
    required this.nom,
    required this.membresIds,
    required this.adminIds,
    required this.codeInvitation,
    required this.dateCreation,
  });

  factory Famille.fromMap(String id, Map<String, dynamic> data) => Famille(
        id: id,
        nom: data['nom'] ?? '',
        membresIds: List<String>.from(data['membresIds'] ?? []),
        adminIds: List<String>.from(data['adminIds'] ?? []),
        codeInvitation: data['codeInvitation'] ?? '',
        dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'membresIds': membresIds,
        'adminIds': adminIds,
        'codeInvitation': codeInvitation,
        'dateCreation': Timestamp.fromDate(dateCreation),
      };
} 