import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_liste/models/famille.dart';
import 'package:my_liste/models/utilisateur.dart';
import 'package:my_liste/models/branche.dart';
import 'package:my_liste/models/liste.dart';
import 'package:my_liste/models/tag.dart';
import 'package:my_liste/models/categorie.dart';
import 'package:my_liste/services/auth_service.dart';

class DatabaseService {
  final FirebaseFirestore _db;

  DatabaseService(this._db);

  /// Crée ou met à jour les données d'un utilisateur dans Firestore.
  Future<void> upsertUser(auth.User user) async {
    final userRef = _db.collection('utilisateurs').doc(user.uid);

    // Crée le document uniquement s'il n'existe pas encore
    // pour ne pas écraser les données (comme familleId) lors de connexions ultérieures.
    final doc = await userRef.get();
    if (!doc.exists) {
      final newUser = Utilisateur(
        id: user.uid,
        email: user.email!,
        nom: user.displayName,
        photoUrl: user.photoURL,
        familleId: '', // Laissé vide à la création
        dateInscription: DateTime.now(),
      );
      await userRef.set(newUser.toMap());
    }
  }

  /// Récupère les données d'un utilisateur depuis Firestore.
  Future<Utilisateur?> getUser(String uid) async {
    final doc = await _db.collection('utilisateurs').doc(uid).get();
    if (doc.exists) {
      return Utilisateur.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Récupère un stream des données d'un utilisateur depuis Firestore.
  Stream<Utilisateur?> userStream(String uid) {
    final userDoc = _db.collection('utilisateurs').doc(uid);
    return userDoc.snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Utilisateur.fromMap(snapshot.id, snapshot.data()!);
      }
      return null;
    });
  }

  /// Récupère un stream de toutes les branches d'une famille.
  Stream<List<Branche>> getBranches(String familleId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Branche.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Récupère une branche spécifique.
  Stream<Branche?> getBranche(String familleId, String brancheId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Branche.fromMap(snapshot.id, snapshot.data()!);
      }
      return null;
    });
  }

  /// Récupère une famille spécifique.
  Stream<Famille?> getFamille(String familleId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Famille.fromMap(snapshot.id, snapshot.data()!);
      }
      return null;
    });
  }

  /// Récupère un stream de toutes les listes d'une branche.
  Stream<List<Liste>> getListes(String familleId, String brancheId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Liste.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Récupère une liste spécifique.
  Stream<Liste?> getListe(String familleId, String brancheId, String listeId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .doc(listeId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Liste.fromMap(snapshot.id, snapshot.data()!);
      }
      return null;
    });
  }

  /// Crée une nouvelle famille et y associe l'utilisateur.
  Future<void> createFamily(String nomFamille, auth.User user) async {
    // 1. Créer la nouvelle famille
    final newFamilyRef = _db.collection('familles').doc();
    final nouvelleFamille = Famille(
      id: newFamilyRef.id,
      nom: nomFamille,
      membresIds: [user.uid],
      adminIds: [user.uid],
      codeInvitation: '', // On pourrait générer un code plus tard
      dateCreation: DateTime.now(),
    );
    await newFamilyRef.set(nouvelleFamille.toMap());

    // 2. Mettre à jour l'utilisateur avec l'ID de la nouvelle famille
    final userRef = _db.collection('utilisateurs').doc(user.uid);
    await userRef.update({'familleId': newFamilyRef.id});
  }

  /// Crée une nouvelle branche dans une famille.
  Future<void> createBranche(String familleId, String nom) async {
    final brancheRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc();
    
    final nouvelleBranche = Branche(
      id: brancheRef.id,
      familleId: familleId,
      nom: nom,
      dateCreation: DateTime.now(),
    );
    
    await brancheRef.set(nouvelleBranche.toMap());
  }

  /// Crée une nouvelle liste dans une branche.
  Future<void> createListe(String familleId, String brancheId, String titre) async {
    final listeRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .doc();
    
    final nouvelleListe = Liste(
      id: listeRef.id,
      brancheId: brancheId,
      titre: titre,
      date: DateTime.now(),
      fermee: false,
      elements: [],
    );
    
    await listeRef.set(nouvelleListe.toMap());
  }

  /// Met à jour l'état d'une liste (ouverte/fermée).
  Future<void> updateListeStatus(String familleId, String brancheId, String listeId, bool fermee) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .doc(listeId)
        .update({'fermee': fermee});
  }

  /// Supprime une liste.
  Future<void> deleteListe(String familleId, String brancheId, String listeId) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .doc(listeId)
        .delete();
  }

  /// Récupère un stream de toutes les catégories d'une famille.
  Stream<List<Categorie>> getCategories(String familleId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('categories')
        .orderBy('ordre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Categorie.fromMap(doc.data()))
            .toList());
  }

  /// Crée une nouvelle catégorie.
  Future<void> createCategorie(String familleId, String nom, int ordre) async {
    final categorieRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('categories')
        .doc();
    
    final nouvelleCategorie = Categorie(
      id: categorieRef.id,
      nom: nom,
      ordre: ordre,
    );
    
    await categorieRef.set(nouvelleCategorie.toMap());
  }

  /// Met à jour une catégorie.
  Future<void> updateCategorie(String familleId, Categorie categorie) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('categories')
        .doc(categorie.id)
        .update(categorie.toMap());
  }

  /// Supprime une catégorie.
  Future<void> deleteCategorie(String familleId, String categorieId) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('categories')
        .doc(categorieId)
        .delete();
  }

  /// Met à jour l'ordre des catégories.
  Future<void> updateCategoriesOrder(String familleId, List<Categorie> categories) async {
    final batch = _db.batch();
    
    for (int i = 0; i < categories.length; i++) {
      final categorie = categories[i];
      final updatedCategorie = Categorie(
        id: categorie.id,
        nom: categorie.nom,
        ordre: i,
        commune: categorie.commune,
      );
      
      final docRef = _db
          .collection('familles')
          .doc(familleId)
          .collection('categories')
          .doc(categorie.id);
      
      batch.update(docRef, updatedCategorie.toMap());
    }
    
    await batch.commit();
  }

  /// Récupère un stream de tous les tags d'une famille.
  Stream<List<Tag>> getTags(String familleId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('tags')
        .orderBy('nom')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tag.fromMap(doc.data()))
            .toList());
  }

  /// Crée ou met à jour un tag.
  Future<void> upsertTag(String familleId, Tag tag) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('tags')
        .doc(tag.id)
        .set(tag.toMap());
  }

  /// Ajoute un élément à une liste.
  Future<void> addElementToListe(String familleId, String brancheId, String listeId, Tag element) async {
    final listeRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .doc(listeId);
    
    await listeRef.update({
      'elements': FieldValue.arrayUnion([element.toMap()])
    });
  }

  /// Met à jour un élément dans une liste.
  Future<void> updateElementInListe(String familleId, String brancheId, String listeId, Tag element) async {
    final listeRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .doc(listeId);
    
    // Récupérer la liste actuelle
    final listeDoc = await listeRef.get();
    if (listeDoc.exists) {
      final liste = Liste.fromMap(listeId, listeDoc.data()!);
      final updatedElements = liste.elements.map((e) {
        if (e.id == element.id) {
          return element;
        }
        return e;
      }).toList();
      
      await listeRef.update({'elements': updatedElements.map((e) => e.toMap()).toList()});
    }
  }

  /// Supprime un élément d'une liste.
  Future<void> removeElementFromListe(String familleId, String brancheId, String listeId, String elementId) async {
    final listeRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .doc(listeId);
    
    // Récupérer la liste actuelle
    final listeDoc = await listeRef.get();
    if (listeDoc.exists) {
      final liste = Liste.fromMap(listeId, listeDoc.data()!);
      final updatedElements = liste.elements.where((e) => e.id != elementId).toList();
      
      await listeRef.update({'elements': updatedElements.map((e) => e.toMap()).toList()});
    }
  }

  /// Récupère tous les éléments (tags) de toutes les listes d'une branche (pour l'autocomplétion).
  Future<List<Tag>> getAllElementsOfBranche(String familleId, String brancheId) async {
    final listesSnap = await _db
        .collection('familles')
        .doc(familleId)
        .collection('branches')
        .doc(brancheId)
        .collection('listes')
        .get();
    final List<Tag> allTags = [];
    for (final doc in listesSnap.docs) {
      final data = doc.data();
      if (data['elements'] != null && data['elements'] is List) {
        for (final tagData in data['elements']) {
          allTags.add(Tag.fromMap(tagData));
        }
      }
    }
    return allTags;
  }
}

// --- PROVIDERS RIVERPOD ---

/// Provider pour l'instance de FirebaseFirestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Provider pour notre DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(firestoreProvider));
});

/// Provider pour le stream des branches de la famille de l'utilisateur actuel.
final branchesProvider = StreamProvider<List<Branche>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getBranches(user.familleId);
  }
  return Stream.value([]);
});

/// Provider pour le stream des listes d'une branche.
final listesProvider = StreamProvider.family<List<Liste>, String>((ref, brancheId) {
  return ref.watch(databaseServiceProvider).getListes(ref.watch(currentUserProvider).value!.familleId, brancheId);
});

/// Provider pour le stream d'une branche spécifique.
final brancheProvider = StreamProvider.family<Branche?, String>((ref, brancheId) {
  return ref.watch(databaseServiceProvider).getBranche(ref.watch(currentUserProvider).value!.familleId, brancheId);
});

/// Provider pour le stream des catégories de la famille de l'utilisateur actuel.
final categoriesProvider = StreamProvider<List<Categorie>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getCategories(user.familleId);
  }
  return Stream.value([]);
});

/// Provider pour le stream des tags de la famille de l'utilisateur actuel.
final tagsProvider = StreamProvider<List<Tag>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getTags(user.familleId);
  }
  return Stream.value([]);
}); 