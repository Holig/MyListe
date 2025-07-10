import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:uni_links/uni_links.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'dart:html' as html;

// Import des pages
import 'pages/accueil_page.dart';
import 'pages/auth_page.dart';
import 'pages/superliste_page.dart';
import 'pages/param_famille_page.dart';
import 'pages/contact_page.dart';
import 'pages/a_propos_page.dart';
import 'pages/liste_detail_page.dart';
import 'pages/creer_famille_page.dart';
import 'pages/join_or_create_family_page.dart';
import 'pages/join_family_from_link_page.dart';
import 'pages/gerer_membres_page.dart';
import 'pages/categories_page.dart';

// Import des services
import 'services/auth_service.dart';
import 'services/database_service.dart';

// Import des modèles
import 'models/utilisateur.dart';
import 'models/famille.dart';
import 'models/superliste.dart';
import 'models/liste.dart';
import 'models/categorie.dart';
import 'models/tag.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Décommenté
  );

  // Gestion des redirections Google Sign-In sur le web
  if (kIsWeb) {
    try {
      final result = await FirebaseAuth.instance.getRedirectResult();
      if (result != null) {
        // L'utilisateur s'est connecté via Google Sign-In
        print('Utilisateur connecté via Google: ${result.user?.email}');
      }
    } catch (e) {
      print('Erreur lors de la récupération du résultat de redirection: $e');
    }
  }

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
        path: '/superliste/:id',
        name: 'superliste',
        builder: (context, state) => SuperlistePage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/liste/:superlisteId/:listeId',
        name: 'liste',
        builder: (context, state) => ListeDetailPage(
          superlisteId: state.pathParameters['superlisteId']!,
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
      GoRoute(
        path: '/join',
        name: 'join_family_from_link',
        builder: (context, state) => JoinFamilyFromLinkPage(
          code: state.uri.queryParameters['family'] ?? '',
        ),
      ),
      GoRoute(
        path: '/gerer-membres',
        name: 'gerer_membres',
        builder: (context, state) => const GererMembresPage(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == '/auth';
      final joiningFamily = state.matchedLocation == '/rejoindre-famille';
      final creatingFamily = state.matchedLocation == '/creer-famille';
      final onSettings = state.matchedLocation == '/famille';

      // Si pas connecté, direction /auth
      if (!isLoggedIn) {
        return loggingIn ? null : '/auth';
      }

      // Si connecté, on attend les données de la bdd
      if (userProvider.isLoading) {
        return null;
      }

      final hasFamily = userProvider.value?.familleActiveId.isNotEmpty ?? false;

      // Si connecté et sur /auth, redirection
      if (loggingIn) {
        return hasFamily ? '/accueil' : '/rejoindre-famille';
      }
      
      // Si connecté sans famille, doit aller sur la page de jonction (sauf s'il est déjà en train de créer)
      if (!hasFamily && !joiningFamily && !creatingFamily) {
        return '/rejoindre-famille';
      }

      // Empêcher la redirection automatique vers /accueil si déjà sur /famille
      if (onSettings) {
        return null;
      }

      return null;
    },
  );
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return DeepLinkListener(
      child: MaterialApp.router(
        title: 'MyListe',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        ),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}

class DeepLinkListener extends StatefulWidget {
  final Widget child;
  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      // Sur mobile, on écoute les liens dynamiques
      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null && uri.path == '/join' && uri.queryParameters['family'] != null) {
          final code = uri.queryParameters['family']!;
          GoRouter.of(context).go('/join?family=$code');
        }
      });
    } else {
      // Sur web, on traite l'URL au chargement
      final uri = Uri.base;
      if (uri.path == '/join' && uri.queryParameters['family'] != null) {
        final code = uri.queryParameters['family']!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).go('/join?family=$code');
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
