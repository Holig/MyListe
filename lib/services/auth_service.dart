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
      // Gérer les erreurs spécifiques à Firebase (ex: user-not-found, wrong-password)
      throw Exception("Erreur de connexion: ${e.message}");
    } catch (e) {
      throw Exception("Une erreur inconnue est survenue.");
    }
  }

  /// Inscription avec e-mail et mot de passe
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _dbService.upsertUser(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs (ex: email-already-in-use)
      throw Exception("Erreur d'inscription: ${e.message}");
    } catch (e) {
      throw Exception("Une erreur inconnue est survenue.");
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
    } catch (e) {
      throw Exception("Erreur de connexion avec Google.");
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