import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// StateProvider pour gérer l'état de chargement
final authLoadingProvider = StateProvider<bool>((ref) => false);

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final isLogin = ref.watch(isLoginProvider);
    final isLoading = ref.watch(authLoadingProvider);

    void showErrorSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }

    Future<void> submit() async {
      if (formKey.currentState!.validate()) {
        ref.read(authLoadingProvider.notifier).state = true;
        try {
          final authService = ref.read(authServiceProvider);
          if (isLogin) {
            await authService.signInWithEmailAndPassword(
              emailController.text.trim(),
              passwordController.text,
            );
          } else {
            await authService.createUserWithEmailAndPassword(
              emailController.text.trim(),
              passwordController.text,
            );
          }
          // La navigation se fera via le Stream authStateChanges
        } catch (e) {
          if (!context.mounted) return;
          // Extraire le message d'erreur proprement
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }
          showErrorSnackBar(errorMessage);
        } finally {
          if (context.mounted) {
            ref.read(authLoadingProvider.notifier).state = false;
          }
        }
      }
    }

    Widget buildGoogleButton(BuildContext context, WidgetRef ref) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Continuer avec Google'),
          onPressed: isLoading
              ? null
              : () async {
                  try {
                    await ref.read(authServiceProvider).signInWithGoogle();
                  } catch (e) {
                    if (context.mounted) {
                      String errorMessage = e.toString();
                      if (errorMessage.startsWith('Exception: ')) {
                        errorMessage = errorMessage.substring(11);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/accueil');
            }
          },
        ),
        title: Text(isLogin ? 'Connexion' : 'Inscription'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isLogin ? 'Bon retour !' : 'Créer un compte',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre adresse e-mail.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Veuillez entrer une adresse e-mail valide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe.';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères.';
                    }
                    // Validation supplémentaire pour l'inscription
                    if (!isLogin) {
                      if (value.length < 8) {
                        return 'Le mot de passe doit contenir au moins 8 caractères.';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Le mot de passe doit contenir au moins une majuscule.';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Le mot de passe doit contenir au moins un chiffre.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isLogin ? 'Se connecter' : 'S\'inscrire'),
                  ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OU'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const SizedBox.shrink()
                else
                  Center(child: buildGoogleButton(context, ref)),
                TextButton(
                  onPressed: isLoading ? null : () {
                    ref.read(isLoginProvider.notifier).state = !isLogin;
                  },
                  child: Text(
                    isLogin
                        ? 'Pas de compte ? S\'inscrire'
                        : 'Déjà un compte ? Se connecter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// StateProvider simple pour basculer entre Connexion et Inscription
final isLoginProvider = StateProvider<bool>((ref) => true); 