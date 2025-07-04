import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart'; // Décommenté
import 'dart:async';

// Import des pages
import 'pages/accueil_page.dart';
import 'pages/auth_page.dart';
import 'pages/branche_page.dart';
import 'pages/creer_famille_page.dart';
import 'pages/param_famille_page.dart';
import 'pages/contact_page.dart';
import 'pages/a_propos_page.dart';
import 'pages/join_or_create_family_page.dart';
import 'pages/liste_detail_page.dart';
import 'services/auth_service.dart'; // Ajout de l'import manquant

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Décommenté
  );
  runApp(const ProviderScope(child: MyApp()));
}

// Provider pour GoRouter
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userProvider = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: GoRouterRefreshStream([
      ref.watch(authStateChangesProvider.stream),
      ref.watch(currentUserProvider.stream),
    ]),
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/accueil',
      ),
      GoRoute(
        path: '/accueil',
        name: 'accueil',
        builder: (context, state) => const AccueilPage(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/rejoindre-famille',
        name: 'rejoindre_famille',
        builder: (context, state) => const JoinOrCreateFamilyPage(),
      ),
      GoRoute(
        path: '/branche/:id',
        name: 'branche',
        builder: (context, state) => BranchePage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/liste/:brancheId/:listeId',
        name: 'liste',
        builder: (context, state) => ListeDetailPage(
          brancheId: state.pathParameters['brancheId']!,
          listeId: state.pathParameters['listeId']!,
        ),
      ),
      GoRoute(
        path: '/creer-famille',
        name: 'creer-famille',
        builder: (context, state) => const CreerFamillePage(),
      ),
      GoRoute(
        path: '/famille',
        name: 'param_famille',
        builder: (context, state) => const ParamFamillePage(),
      ),
      GoRoute(
        path: '/contact',
        name: 'contact',
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: '/a-propos',
        name: 'a_propos',
        builder: (context, state) => const AProposPage(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == '/auth';
      final joiningFamily = state.matchedLocation == '/rejoindre-famille';
      final creatingFamily = state.matchedLocation == '/creer-famille';

      // Si pas connecté, direction /auth
      if (!isLoggedIn) {
        return loggingIn ? null : '/auth';
      }

      // Si connecté, on attend les données de la bdd
      if (userProvider.isLoading) {
        return null;
      }

      final hasFamily = userProvider.value?.familleId.isNotEmpty ?? false;

      // Si connecté et sur /auth, redirection
      if (loggingIn) {
        return hasFamily ? '/accueil' : '/rejoindre-famille';
      }
      
      // Si connecté sans famille, doit aller sur la page de jonction (sauf s'il est déjà en train de créer)
      if (!hasFamily && !joiningFamily && !creatingFamily) {
        return '/rejoindre-famille';
      }
      
      // Si connecté avec famille et sur une page de "setup", redirection vers l'accueil
      if (hasFamily && (joiningFamily || creatingFamily)) {
        return '/accueil';
      }

      return null;
    },
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'MyListe',
      theme: ThemeData(
        primarySwatch: Colors.green,
        // fontFamily: 'Poppins', // Commenté car les polices ne sont pas encore ajoutées
      ),
      routerConfig: router,
    );
  }
}

// Helper class pour GoRouter, maintenant capable de gérer plusieurs streams
class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  GoRouterRefreshStream(List<Stream<dynamic>> streams) {
    _subscriptions = streams
        .map((stream) =>
            stream.asBroadcastStream().listen((_) => notifyListeners()))
        .toList();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

// AUCUN WIDGET DE PAGE NE DOIT ÊTRE DÉFINI ICI
