import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:js/js_util.dart' as js_util;
import 'dart:async';
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
  void initState() {
    super.initState();
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'google-signin-button',
        (int viewId) {
          final div = html.DivElement();
          div.id = 'g_id_onload';
          div.setAttribute('data-client_id', '400867505180-04v417e92s2jl4qrcqb58pgu726qvv0j.apps.googleusercontent.com');
          div.setAttribute('data-context', 'signin');
          div.setAttribute('data-ux_mode', 'popup');
          div.setAttribute('data-callback', 'onGoogleSignIn');
          div.setAttribute('data-auto_prompt', 'false');
          final button = html.Element.tag('div');
          button.id = 'g_id_signin';
          button.setAttribute('data-type', 'standard');
          button.setAttribute('data-shape', 'rectangular');
          button.setAttribute('data-theme', 'outline');
          button.setAttribute('data-text', 'signin_with');
          button.setAttribute('data-size', 'large');
          button.setAttribute('data-logo_alignment', 'left');
          div.append(button);
          return div;
        },
      );
      html.window.onMessage.listen((event) async {
        final credential = event.data;
        if (credential != null && credential is String && credential.length > 100) {
          try {
            final firebaseCredential = GoogleAuthProvider.credential(idToken: credential);
            await FirebaseAuth.instance.signInWithCredential(firebaseCredential);
            // Afficher un message de succès ou naviguer
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur Google/Firebase: $e'), backgroundColor: Colors.red),
            );
          }
        }
      });
    }
  }

  Widget _buildGoogleWebButton(BuildContext context, WidgetRef ref) {
    // Supprime l'ancien bouton s'il existe
    final oldButton = html.document.getElementById('g_id_signin');
    if (oldButton != null) {
      oldButton.remove();
    }
    // Enregistre le viewType à chaque build
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'google-signin-button',
      (int viewId) {
        final div = html.DivElement();
        div.id = 'g_id_onload';
        div.setAttribute('data-client_id', '400867505180-04v417e92s2jl4qrcqb58pgu726qvv0j.apps.googleusercontent.com');
        div.setAttribute('data-context', 'signin');
        div.setAttribute('data-ux_mode', 'popup');
        div.setAttribute('data-callback', 'onGoogleSignIn');
        div.setAttribute('data-auto_prompt', 'false');
        final button = html.Element.tag('div');
        button.id = 'g_id_signin';
        button.setAttribute('data-type', 'standard');
        button.setAttribute('data-shape', 'rectangular');
        button.setAttribute('data-theme', 'outline');
        button.setAttribute('data-text', 'signin_with');
        button.setAttribute('data-size', 'large');
        button.setAttribute('data-logo_alignment', 'left');
        div.append(button);
        // Timer pour attendre que le script Google soit prêt
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          final google = js_util.getProperty(html.window, 'google');
          if (google != null &&
              js_util.hasProperty(google, 'accounts') &&
              js_util.hasProperty(js_util.getProperty(google, 'accounts'), 'id')) {
            js_util.callMethod(
              js_util.getProperty(js_util.getProperty(google, 'accounts'), 'id'),
              'renderButton',
              [
                button,
                {
                  'type': 'standard',
                  'theme': 'outline',
                  'size': 'large',
                  'width': 240,
                },
              ],
            );
            timer.cancel();
          }
        });
        return div;
      },
    );
    return const SizedBox(
      width: 240,
      height: 48,
      child: HtmlElementView(viewType: 'google-signin-button'),
    );
  }

  Widget _buildGoogleButton(BuildContext context, WidgetRef ref) {
    // Ton bouton Google classique pour mobile
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.g_mobiledata),
        label: const Text('Continuer avec Google'),
        onPressed: () async {
          try {
            await ref.read(authServiceProvider).signInWithGoogle();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur Google: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

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
              emailController.text,
              passwordController.text,
            );
          } else {
            await authService.createUserWithEmailAndPassword(
              emailController.text,
              passwordController.text,
            );
          }
          // La navigation se fera via le Stream authStateChanges
        } catch (e) {
          if (!context.mounted) return;
          showErrorSnackBar(e.toString());
        } finally {
          if (context.mounted) {
            ref.read(authLoadingProvider.notifier).state = false;
          }
        }
      }
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
                    if (value == null || value.isEmpty || !value.contains('@')) {
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
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères.';
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
                  kIsWeb
                      ? const GoogleWebButton()
                      : _buildGoogleButton(context, ref),
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

class GoogleWebButton extends StatefulWidget {
  const GoogleWebButton({super.key});
  @override
  State<GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<GoogleWebButton> {
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType = 'google-signin-button-${DateTime.now().millisecondsSinceEpoch}';

    // Supprime tous les anciens boutons Google du DOM
    html.document.querySelectorAll('#g_id_signin').forEach((e) => e.remove());

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final div = html.DivElement();
        div.id = 'g_id_signin';
        // On attend que le script soit chargé avant d'appeler renderButton
        Future.delayed(const Duration(milliseconds: 200), () {
          final google = js_util.getProperty(html.window, 'google');
          if (google != null &&
              js_util.hasProperty(google, 'accounts') &&
              js_util.hasProperty(js_util.getProperty(google, 'accounts'), 'id')) {
            js_util.callMethod(
              js_util.getProperty(js_util.getProperty(google, 'accounts'), 'id'),
              'renderButton',
              [
                div,
                {
                  'client_id': '400867505180-04v417ye92s2jl4qrcqb58gpu726qv0j.apps.googleusercontent.com',
                  'callback': js_util.getProperty(html.window, 'onGoogleSignIn'),
                  'type': 'standard',
                  'theme': 'outline',
                  'size': 'large',
                  'width': 240,
                  'shape': 'rectangular',
                  'logo_alignment': 'left',
                }
              ],
            );
          }
        });
        return div;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 48,
      child: HtmlElementView(viewType: viewType),
    );
  }
} 