import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

Future<UserCredential> signInWithGoogle(FirebaseAuth auth, DatabaseService dbService) async {
  final GoogleAuthProvider googleProvider = GoogleAuthProvider();
  googleProvider.addScope('email');
  googleProvider.addScope('profile');
  final userCredential = await auth.signInWithPopup(googleProvider);
  await dbService.upsertUser(userCredential.user!);
  return userCredential;
} 