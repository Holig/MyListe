import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_liste/models/famille.dart';
import 'package:my_liste/models/utilisateur.dart';
import 'package:my_liste/models/superliste.dart';
import 'package:my_liste/models/liste.dart';
import 'package:my_liste/models/tag.dart';
import 'package:my_liste/models/categorie.dart';
import 'package:my_liste/models/historique_action.dart';
import 'package:my_liste/services/auth_service.dart';

class DatabaseService {
  final FirebaseFirestore _db;

  DatabaseService(this._db);

  /// Crée ou met à jour les données d'un utilisateur dans Firestore.
  Future<void> upsertUser(auth.User user) async {
    final userRef = _db.collection('utilisateurs').doc(user.uid);
    final doc = await userRef.get();
    if (!doc.exists) {
      final newUser = Utilisateur(
        id: user.uid,
        email: user.email!,
        nom: user.displayName,
        photoUrl: user.photoURL,
        famillesIds: [],
        familleActiveId: '',
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

  /// Récupère un stream de toutes les superlistes d'une famille.
  Stream<List<Superliste>> getSuperlistes(String familleId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Superliste.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Récupère une superliste spécifique.
  Stream<Superliste?> getSuperliste(String familleId, String superlisteId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Superliste.fromMap(snapshot.id, snapshot.data()!);
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

  /// Récupère un stream de toutes les listes d'une superliste.
  Stream<List<Liste>> getListes(String familleId, String superlisteId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Liste.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Récupère une liste spécifique.
  Stream<Liste?> getListe(String familleId, String superlisteId, String listeId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
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
    final newFamilyRef = _db.collection('familles').doc();
    final codeInvitation = _generateInvitationCode();
    final nouvelleFamille = Famille(
      id: newFamilyRef.id,
      nom: nomFamille,
      membresIds: [user.uid],
      adminIds: [user.uid],
      codeInvitation: codeInvitation,
      dateCreation: DateTime.now(),
    );
    await newFamilyRef.set(nouvelleFamille.toMap());
    final userRef = _db.collection('utilisateurs').doc(user.uid);
    await userRef.update({
      'famillesIds': FieldValue.arrayUnion([newFamilyRef.id]),
      'familleActiveId': newFamilyRef.id,
    });
  }

  /// Crée une nouvelle superliste dans une famille.
  Future<void> createSuperliste(String familleId, String nom) async {
    final superlisteRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc();
    
    final nouvelleSuperliste = Superliste(
      id: superlisteRef.id,
      familleId: familleId,
      nom: nom,
      dateCreation: DateTime.now(),
    );
    
    await superlisteRef.set(nouvelleSuperliste.toMap());
  }

  /// Crée une nouvelle liste dans une superliste (adapté pour sous-collection)
  Future<void> createListe(String familleId, String superlisteId, String titre, {List<Tag>? elements}) async {
    final listeRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc();
    final nouvelleListe = Liste(
      id: listeRef.id,
      superlisteId: superlisteId,
      titre: titre,
      date: DateTime.now(),
      fermee: false,
    );
    await listeRef.set(nouvelleListe.toMap());
    // Ajout des éléments dans la sous-collection
    if (elements != null && elements.isNotEmpty) {
      final itemsRef = listeRef.collection('items');
      for (final element in elements) {
        await itemsRef.doc(element.id).set(element.toMap());
      }
    }
  }

  /// Met à jour l'état d'une liste (ouverte/fermée).
  Future<void> updateListeStatus(String familleId, String superlisteId, String listeId, bool fermee) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .update({'fermee': fermee});
  }

  /// Supprime une liste.
  Future<void> deleteListe(String familleId, String superlisteId, String listeId) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .delete();
  }

  /// Récupère un stream de toutes les catégories d'une superliste.
  Stream<List<Categorie>> getCategories(String familleId, String superlisteId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('categories')
        .orderBy('ordre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Categorie.fromMap(doc.data()))
            .toList());
  }

  /// Crée une nouvelle catégorie dans une superliste.
  Future<void> createCategorie(String familleId, String superlisteId, String nom, int ordre) async {
    final categorieRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('categories')
        .doc();
    
    final nouvelleCategorie = Categorie(
      id: categorieRef.id,
      nom: nom,
      ordre: ordre,
      superlisteId: superlisteId,
    );
    
    await categorieRef.set(nouvelleCategorie.toMap());
  }

  /// Met à jour une catégorie.
  Future<void> updateCategorie(String familleId, String superlisteId, Categorie categorie) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('categories')
        .doc(categorie.id)
        .update(categorie.toMap());
  }

  /// Supprime une catégorie.
  Future<void> deleteCategorie(String familleId, String superlisteId, String categorieId) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('categories')
        .doc(categorieId)
        .delete();
  }

  /// Met à jour l'ordre des catégories.
  Future<void> updateCategoriesOrder(String familleId, String superlisteId, List<Categorie> categories) async {
    final batch = _db.batch();
    
    for (int i = 0; i < categories.length; i++) {
      final categorie = categories[i];
      final updatedCategorie = Categorie(
        id: categorie.id,
        nom: categorie.nom,
        ordre: i,
        superlisteId: superlisteId,
      );
      
      final docRef = _db
          .collection('familles')
          .doc(familleId)
          .collection('superlistes')
          .doc(superlisteId)
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

  /// Ajoute un élément à une liste (nouvelle version sous-collection)
  Future<void> addElementToListe(String familleId, String superlisteId, String listeId, Tag element) async {
    final itemsRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .collection('items');
    await itemsRef.doc(element.id).set(element.toMap());
  }

  /// Met à jour un élément dans une liste (nouvelle version sous-collection)
  Future<void> updateElementInListe(String familleId, String superlisteId, String listeId, Tag element) async {
    final itemRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .collection('items')
        .doc(element.id);
    await itemRef.update(element.toMap());
  }

  /// Supprime un élément d'une liste (nouvelle version sous-collection)
  Future<void> removeElementFromListe(String familleId, String superlisteId, String listeId, String elementId) async {
    final itemRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .collection('items')
        .doc(elementId);
    await itemRef.delete();
  }

  /// Récupère tous les éléments (tags) de toutes les listes d'une superliste (pour l'autocomplétion)
  Future<List<Tag>> getAllElementsOfSuperliste(String familleId, String superlisteId) async {
    final listesSnap = await _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .get();
    final List<Tag> allTags = [];
    for (final doc in listesSnap.docs) {
      final itemsSnap = await doc.reference.collection('items').get();
      for (final itemDoc in itemsSnap.docs) {
        allTags.add(Tag.fromMap(itemDoc.data()));
      }
    }
    return allTags;
  }

  /// Récupère un stream des éléments d'une liste (pour l'UI)
  Stream<List<Tag>> getElementsStream(String familleId, String superlisteId, String listeId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .collection('items')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Tag.fromMap(d.data())).toList());
  }

  /// Ajoute une action à l'historique d'une liste
  Future<void> addHistoriqueAction({
    required String familleId,
    required String superlisteId,
    required String listeId,
    required HistoriqueAction action,
  }) async {
    final historiqueRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .collection('historique')
        .doc();
    await historiqueRef.set(action.toMap());
  }

  /// Récupère le stream de l'historique d'une liste
  Stream<List<HistoriqueAction>> getHistoriqueActions(String familleId, String superlisteId, String listeId) {
    return _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .collection('historique')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HistoriqueAction.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Ajoute une action à l'historique des catégories d'une superliste
  Future<void> addCategorieHistoriqueAction({
    required String familleId,
    required String superlisteId,
    required HistoriqueAction action,
  }) async {
    final historiqueRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('categories_historique')
        .doc();
    await historiqueRef.set(action.toMap());
  }

  /// Génère un code d'invitation unique pour une famille.
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    for (int i = 0; i < 8; i++) {
      final index = (rand * (i + 1) + (rand >> (i + 2))) % chars.length;
      code.write(chars[index]);
    }
    return code.toString();
  }

  /// Génère ou régénère le code d'invitation d'une famille.
  Future<String> generateInvitationCode(String familleId) async {
    final code = _generateInvitationCode();
    
    await _db
        .collection('familles')
        .doc(familleId)
        .update({'codeInvitation': code});
    
    return code;
  }

  /// Rejoint une famille avec un code d'invitation.
  Future<void> joinFamilyWithCode(String codeInvitation, auth.User user) async {
    final familleQuery = await _db
        .collection('familles')
        .where('codeInvitation', isEqualTo: codeInvitation)
        .get();
    if (familleQuery.docs.isEmpty) {
      throw Exception('Code d\'invitation invalide');
    }
    final familleDoc = familleQuery.docs.first;
    final famille = Famille.fromMap(familleDoc.id, familleDoc.data());
    if (famille.membresIds.contains(user.uid)) {
      throw Exception('Vous êtes déjà membre de cette famille');
    }
    final updatedMembresIds = [...famille.membresIds, user.uid];
    await familleDoc.reference.update({'membresIds': updatedMembresIds});
    final userRef = _db.collection('utilisateurs').doc(user.uid);
    await userRef.update({
      'famillesIds': FieldValue.arrayUnion([famille.id]),
      'familleActiveId': famille.id,
    });
  }

  /// Quitter une famille (retire l'utilisateur de la famille et met à jour ses famillesIds/familleActiveId)
  Future<void> quitFamily(String familleId, auth.User user) async {
    final familleRef = _db.collection('familles').doc(familleId);
    final familleDoc = await familleRef.get();
    if (!familleDoc.exists) return;
    final famille = Famille.fromMap(familleDoc.id, familleDoc.data()!);
    final updatedMembresIds = famille.membresIds.where((id) => id != user.uid).toList();
    await familleRef.update({'membresIds': updatedMembresIds});
    final userRef = _db.collection('utilisateurs').doc(user.uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final utilisateur = Utilisateur.fromMap(user.uid, userDoc.data()!);
    final updatedFamillesIds = utilisateur.famillesIds.where((id) => id != familleId).toList();
    String newActive = utilisateur.familleActiveId;
    if (newActive == familleId) {
      newActive = updatedFamillesIds.isNotEmpty ? updatedFamillesIds.first : '';
    }
    await userRef.update({
      'famillesIds': updatedFamillesIds,
      'familleActiveId': newActive,
    });
  }

  /// Change la famille active de l'utilisateur
  Future<void> setActiveFamily(String familleId, auth.User user) async {
    final userRef = _db.collection('utilisateurs').doc(user.uid);
    await userRef.update({'familleActiveId': familleId});
  }

  /// Promeut un membre en admin
  Future<void> promoteToAdmin(String familleId, String userId) async {
    final familleRef = _db.collection('familles').doc(familleId);
    await familleRef.update({
      'adminIds': FieldValue.arrayUnion([userId])
    });
  }

  /// Rétrograde un admin en membre (sauf propriétaire)
  Future<void> demoteFromAdmin(String familleId, String userId) async {
    final familleRef = _db.collection('familles').doc(familleId);
    final familleDoc = await familleRef.get();
    if (!familleDoc.exists) return;
    final famille = Famille.fromMap(familleDoc.id, familleDoc.data()!);
    // Ne pas retirer le propriétaire (premier admin)
    if (famille.adminIds.isNotEmpty && famille.adminIds.first == userId) return;
    final updatedAdmins = famille.adminIds.where((id) => id != userId).toList();
    await familleRef.update({'adminIds': updatedAdmins});
  }

  /// Retire un membre d'une famille (et le retire aussi des admins si besoin)
  Future<void> removeMember(String familleId, String userId) async {
    final familleRef = _db.collection('familles').doc(familleId);
    final familleDoc = await familleRef.get();
    if (!familleDoc.exists) return;
    final famille = Famille.fromMap(familleDoc.id, familleDoc.data()!);
    // Ne pas retirer le propriétaire
    if (famille.adminIds.isNotEmpty && famille.adminIds.first == userId) return;
    final updatedMembres = famille.membresIds.where((id) => id != userId).toList();
    final updatedAdmins = famille.adminIds.where((id) => id != userId).toList();
    await familleRef.update({'membresIds': updatedMembres, 'adminIds': updatedAdmins});
  }

  /// Met à jour le dégradé d'une famille
  Future<void> updateFamilyGradient(String familleId, String color1, String color2) async {
    final familleRef = _db.collection('familles').doc(familleId);
    await familleRef.update({
      'gradientColor1': color1,
      'gradientColor2': color2,
    });
  }

  /// Met à jour le nom d'une superliste
  Future<void> updateSuperlisteName(String familleId, String superlisteId, String nouveauNom) async {
    await _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .update({'nom': nouveauNom});
  }

  /// Met à jour le nom d'une famille
  Future<void> updateFamilyName(String familleId, String nouveauNom) async {
    final familleRef = _db.collection('familles').doc(familleId);
    await familleRef.update({'nom': nouveauNom});
  }

  /// Supprime toutes les entrées d'historique d'une liste
  Future<void> deleteAllHistoriqueActions(String familleId, String superlisteId, String listeId) async {
    final historiqueRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId)
        .collection('historique');
    final batch = _db.batch();
    final snapshot = await historiqueRef.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Met à jour le type de palette de la famille
  Future<void> updateFamilyPaletteType(String familleId, String paletteType) async {
    final familleRef = _db.collection('familles').doc(familleId);
    await familleRef.update({'paletteType': paletteType});
  }

  /// Met à jour la liste des dégradés personnalisés de la famille
  Future<void> updateFamilyCustomGradients(String familleId, List<List<String>> gradients) async {
    final familleRef = _db.collection('familles').doc(familleId);
    await familleRef.update({'customGradients': gradients});
  }

  Future<void> updateListeName(String familleId, String superlisteId, String listeId, String nouveauNom) async {
    final listeRef = _db
        .collection('familles')
        .doc(familleId)
        .collection('superlistes')
        .doc(superlisteId)
        .collection('listes')
        .doc(listeId);
    await listeRef.update({'titre': nouveauNom});
  }
}

// --- PROVIDERS RIVERPOD ---

/// Provider pour l'instance de FirebaseFirestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Provider pour notre DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(firestoreProvider));
});

/// Provider pour le stream des superlistes de la famille active de l'utilisateur actuel.
final superlistesProvider = StreamProvider<List<Superliste>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleActiveId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getSuperlistes(user.familleActiveId);
  }
  return Stream.value([]);
});

/// Provider pour le stream des listes d'une superliste.
final listesProvider = StreamProvider.family<List<Liste>, String>((ref, superlisteId) {
  final user = ref.watch(currentUserProvider).value;
  return ref.watch(databaseServiceProvider).getListes(user!.familleActiveId, superlisteId);
});

/// Provider pour le stream d'une superliste spécifique.
final superlisteProvider = StreamProvider.family<Superliste?, String>((ref, superlisteId) {
  final user = ref.watch(currentUserProvider).value;
  return ref.watch(databaseServiceProvider).getSuperliste(user!.familleActiveId, superlisteId);
});

/// Provider pour le stream des catégories d'une superliste.
final categoriesProvider = StreamProvider.family<List<Categorie>, String>((ref, superlisteId) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleActiveId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getCategories(user.familleActiveId, superlisteId);
  }
  return Stream.value([]);
});

/// Provider pour le stream des tags de la famille active de l'utilisateur actuel.
final tagsProvider = StreamProvider<List<Tag>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleActiveId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getTags(user.familleActiveId);
  }
  return Stream.value([]);
}); 