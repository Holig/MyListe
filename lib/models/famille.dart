import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une famille (groupe d'utilisateurs)
class Famille {
  final String id;
  final String nom;
  final List<String> membresIds;
  final List<String> adminIds;
  final String codeInvitation;
  final DateTime dateCreation;
  final String gradientColor1;
  final String gradientColor2;

  Famille({
    required this.id,
    required this.nom,
    required this.membresIds,
    required this.adminIds,
    required this.codeInvitation,
    required this.dateCreation,
    this.gradientColor1 = '#8e2de2',
    this.gradientColor2 = '#4a00e0',
  });

  factory Famille.fromMap(String id, Map<String, dynamic> data) => Famille(
        id: id,
        nom: data['nom'] ?? '',
        membresIds: List<String>.from(data['membresIds'] ?? []),
        adminIds: List<String>.from(data['adminIds'] ?? []),
        codeInvitation: data['codeInvitation'] ?? '',
        dateCreation: (data['dateCreation'] as Timestamp).toDate(),
        gradientColor1: data['gradientColor1'] ?? '#8e2de2',
        gradientColor2: data['gradientColor2'] ?? '#4a00e0',
      );

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'membresIds': membresIds,
        'adminIds': adminIds,
        'codeInvitation': codeInvitation,
        'dateCreation': Timestamp.fromDate(dateCreation),
        'gradientColor1': gradientColor1,
        'gradientColor2': gradientColor2,
      };
} 