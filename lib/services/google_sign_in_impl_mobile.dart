import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

Future<UserCredential> signInWithGooglePlatform(FirebaseAuth auth, DatabaseService dbService) async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    throw Exception('Connexion avec Google annulée.');
  }
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  final userCredential = await auth.signInWithCredential(credential);
  await dbService.upsertUser(userCredential.user!);
  return userCredential;
} 