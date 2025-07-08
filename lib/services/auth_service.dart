import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_liste/models/utilisateur.dart';
import 'database_service.dart'; // Importer le service de base de données
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final DatabaseService _dbService;

  AuthService(this._auth, this._googleSignIn, this._dbService);

  /// Getter pour l'utilisateur actuellement authentifié
  User? get currentUser => _auth.currentUser;

  // --- STREAMS ---
  /// Stream pour écouter les changements d'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- METHODES ---
  /// Connexion avec e-mail et mot de passe
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _dbService.upsertUser(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs spécifiques à Firebase
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cette adresse e-mail.';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          errorMessage = 'Adresse e-mail invalide.';
          break;
        case 'user-disabled':
          errorMessage = 'Ce compte a été désactivé.';
          break;
        case 'too-many-requests':
          errorMessage = 'Trop de tentatives de connexion. Veuillez réessayer plus tard.';
          break;
        default:
          errorMessage = 'Erreur de connexion: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Erreur d\'authentification: $e');
      throw Exception("Une erreur inconnue est survenue lors de la connexion.");
    }
  }

  /// Inscription avec e-mail et mot de passe
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _dbService.upsertUser(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs spécifiques à Firebase
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cette adresse e-mail est déjà utilisée.';
          break;
        case 'invalid-email':
          errorMessage = 'Adresse e-mail invalide.';
          break;
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'L\'inscription par e-mail n\'est pas activée.';
          break;
        default:
          errorMessage = 'Erreur d\'inscription: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Erreur d\'inscription: $e');
      throw Exception("Une erreur inconnue est survenue lors de l'inscription.");
    }
  }

  /// Connexion avec Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        throw Exception('Connexion avec Google annulée.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _dbService.upsertUser(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'Un compte existe déjà avec cette adresse e-mail mais avec une méthode de connexion différente.';
          break;
        case 'invalid-credential':
          errorMessage = 'Les informations d\'identification Google sont invalides.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'La connexion avec Google n\'est pas activée.';
          break;
        case 'user-disabled':
          errorMessage = 'Ce compte a été désactivé.';
          break;
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec ces informations d\'identification.';
          break;
        default:
          errorMessage = 'Erreur de connexion avec Google: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Erreur Google Sign-In: $e');
      throw Exception("Erreur de connexion avec Google. Veuillez réessayer.");
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

// --- PROVIDERS RIVERPOD ---

/// Provider pour l'instance de FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Provider pour l'instance de GoogleSignIn
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  if (kIsWeb) {
    return GoogleSignIn(
      clientId: '400867505180-04v417e92s2jl4qrcqb58pgu726qvv0j.apps.googleusercontent.com',
      // Ajoutez ici d'autres options si besoin
    );
  } else {
    return GoogleSignIn();
  }
});

/// Provider pour notre AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(databaseServiceProvider), // Injecter DatabaseService
  );
});

/// Provider pour le stream de l'état d'authentification
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provider pour récupérer les données de l'utilisateur connecté depuis Firestore.
final currentUserProvider = StreamProvider<Utilisateur?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value != null) {
    return ref.watch(databaseServiceProvider).userStream(authState.value!.uid);
  }
  return Stream.value(null);
}); 