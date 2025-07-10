import 'package:cloud_firestore/cloud_firestore.dart';

class HistoriqueAction {
  final String id;
  final String userId;
  final String type; // ajout, suppression, modification
  final String elementNom;
  final String? ancienneValeur;
  final String? nouvelleValeur;
  final DateTime date;

  HistoriqueAction({
    required this.id,
    required this.userId,
    required this.type,
    required this.elementNom,
    this.ancienneValeur,
    this.nouvelleValeur,
    required this.date,
  });

  factory HistoriqueAction.fromMap(String id, Map<String, dynamic> data) => HistoriqueAction(
    id: id,
    userId: data['userId'] ?? '',
    type: data['type'] ?? '',
    elementNom: data['elementNom'] ?? '',
    ancienneValeur: data['ancienneValeur'],
    nouvelleValeur: data['nouvelleValeur'],
    date: (data['date'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type,
    'elementNom': elementNom,
    'ancienneValeur': ancienneValeur,
    'nouvelleValeur': nouvelleValeur,
    'date': Timestamp.fromDate(date),
  };
} 