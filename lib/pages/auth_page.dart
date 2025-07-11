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
        title: Text(isLogin ? 'Connexion' : 'Inscription'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_myliste.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/logo__myliste.png',
                          height: 240,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Organisez vos listes en famille',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Adresse e-mail',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.85),
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
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.85),
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
                    // Ajoute le lien mot de passe oublié (seulement en mode connexion)
                    if (isLogin) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : () async {
                            final email = emailController.text.trim();
                            final controller = TextEditingController(text: email);
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Réinitialiser le mot de passe'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Adresse e-mail',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                                    child: const Text('Envoyer'),
                                  ),
                                ],
                              ),
                            );
                            if (result != null && result.isNotEmpty) {
                              try {
                                await ref.read(authServiceProvider).resetPassword(result);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Un email de réinitialisation a été envoyé.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                    ],
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
        ],
      ),
    );
  }
}

// StateProvider simple pour basculer entre Connexion et Inscription
final isLoginProvider = StateProvider<bool>((ref) => true); 