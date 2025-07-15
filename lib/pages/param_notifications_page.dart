import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/utilisateur.dart';

const List<String> eventTypes = [
  'ajout',
  'suppression',
  'modification',
  'validation',
  'invitation',
];

class ParamNotificationsPage extends ConsumerWidget {
  final Utilisateur user;
  final List<String> famillesIds;
  const ParamNotificationsPage({required this.user, required this.famillesIds, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications par famille')), 
      body: ListView(
        children: famillesIds.map((familleId) {
          final docRef = FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(user.id)
              .collection('notifications')
              .doc(familleId);
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: docRef.snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Famille : $familleId', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...eventTypes.map((event) {
                        final active = data[event] ?? true;
                        return SwitchListTile(
                          title: Text('Notification "$event"'),
                          value: active,
                          onChanged: (val) {
                            docRef.set({event: val}, SetOptions(merge: true));
                          },
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
} 