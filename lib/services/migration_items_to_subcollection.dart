import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Script de migration à exécuter une seule fois !
Future<void> migrateItemsToSubcollection() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;

  // On suppose que la structure est familles/{familleId}/superlistes/{superlisteId}/listes/{listeId}
  final familles = await firestore.collection('familles').get();
  for (final familleDoc in familles.docs) {
    final superlistes = await familleDoc.reference.collection('superlistes').get();
    for (final superlisteDoc in superlistes.docs) {
      final listes = await superlisteDoc.reference.collection('listes').get();
      for (final listeDoc in listes.docs) {
        final data = listeDoc.data();
        final items = data['elements'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          print('Migration de ${items.length} éléments pour la liste ${listeDoc.id}');
          for (final item in items) {
            // On suppose que chaque item est une Map<String, dynamic>
            await listeDoc.reference.collection('items').add(Map<String, dynamic>.from(item));
          }
          // Optionnel : supprimer le tableau d'éléments du document principal
          await listeDoc.reference.update({'elements': FieldValue.delete()});
        }
      }
    }
  }
  print('Migration terminée !');
} 