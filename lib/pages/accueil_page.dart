import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/pages/categories_page.dart';
import 'package:my_liste/pages/param_famille_page.dart';
import 'package:my_liste/pages/contact_page.dart';
import 'package:my_liste/pages/a_propos_page.dart';
import 'package:my_liste/models/famille.dart';
import 'package:my_liste/main.dart' show themeModeProvider;
import 'package:my_liste/models/superliste.dart';

class AccueilPage extends ConsumerStatefulWidget {
  const AccueilPage({super.key});

  @override
  ConsumerState<AccueilPage> createState() => _AccueilPageState();
}

final tabIndexProvider = StateProvider<int>((ref) => 0);

// 1. Ajouter un provider pour récupérer toutes les familles de l'utilisateur
final allFamillesProvider = StreamProvider<List<Famille>>((ref) async* {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.famillesIds.isNotEmpty) {
    final db = ref.watch(databaseServiceProvider);
    final familles = await Future.wait(user.famillesIds.map((familleId) => db.getFamille(familleId).first));
    yield familles.whereType<Famille>().toList();
  } else {
    yield [];
  }
});

// Provider familial pour les superlistes d'une famille
final superlistesParFamilleProvider = StreamProvider.family<List<Superliste>, String>((ref, familleId) {
  return ref.watch(databaseServiceProvider).getSuperlistes(familleId);
});

class _AccueilPageState extends ConsumerState<AccueilPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(tabIndexProvider);
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != ref.read(tabIndexProvider)) {
        ref.read(tabIndexProvider.notifier).state = _tabController.index;
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AccueilPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wantedIndex = ref.read(tabIndexProvider);
    if (_tabController.index != wantedIndex) {
      _tabController.index = wantedIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo_myliste_line.png',
          height: 48,
          fit: BoxFit.contain,
        ),
        automaticallyImplyLeading: false,
        toolbarHeight: 56,
        bottom: null,
      ),
      body: Column(
        children: [
          // Barre secondaire : actions + onglets
          Material(
            color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopActionsBar(context),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.list_alt),
                      text: 'Superlistes',
                    ),
                    Tab(
                      icon: Icon(Icons.family_restroom),
                      text: 'Paramètres Familles',
                    ),
                    Tab(
                      icon: Icon(Icons.contact_support),
                      text: 'Contact',
                    ),
                    Tab(
                      icon: Icon(Icons.info),
                      text: 'À propos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Supprimer la ligne colorée de la famille active sous les onglets (dans build)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuperlistesTab(),
                _buildParametresFamillesTab(),
                _buildContactTab(),
                _buildAProposTab(),
              ],
            ),
          ),
        ],
      ),
      // Supprimer le bouton flottant (floatingActionButton) du Scaffold
    );
  }

  Widget _buildSuperlistesTab() {
    final famillesAsync = ref.watch(allFamillesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Titre de section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              const Icon(Icons.list_alt, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Mes Superlistes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Liste des familles et superlistes
        Expanded(
          child: famillesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
            data: (familles) {
              if (familles.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune famille trouvée.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Créez ou rejoignez une famille pour commencer.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: familles.length,
                itemBuilder: (context, famIndex) {
                  final famille = familles[famIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bandeau famille avec bouton +
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              hexToColor(famille.gradientColor1),
                              hexToColor(famille.gradientColor2),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Famille "${famille.nom}"',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              tooltip: 'Créer une superliste pour cette famille',
                              onPressed: () => _showCreateSuperlisteDialogForFamille(context, ref, famille.id),
                            ),
                          ],
                        ),
                      ),
                      // Superlistes de la famille
                      Consumer(
                        builder: (context, ref, _) {
                          final superlistesAsync = ref.watch(superlistesParFamilleProvider(famille.id));
                          return superlistesAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (err, stack) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(child: Text('Erreur: $err')),
                            ),
                            data: (superlistes) {
                              if (superlistes.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Aucune superliste pour cette famille.', style: TextStyle(color: Colors.white)),
                                );
                              }
                              return Column(
                                children: superlistes.map((superliste) => Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.list_alt)),
                                    title: Text(superliste.nom),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                    onTap: () {
                                      context.go('/superliste/${superliste.id}');
                                    },
                                  ),
                                )).toList(),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParametresFamillesTab() {
    return const ParamFamillePage();
  }

  Widget _buildContactTab() {
    return const ContactPage();
  }

  Widget _buildAProposTab() {
    return const AProposPage();
  }

  void _showCreateSuperlisteDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une nouvelle superliste'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom de la superliste',
            hintText: 'Ex: Courses, Séries, Activités',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _createSuperliste(context, ref, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _createSuperliste(context, ref, controller.text.trim());
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour créer une superliste pour une famille spécifique
  void _showCreateSuperlisteDialogForFamille(BuildContext context, WidgetRef ref, String familleId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une nouvelle superliste'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom de la superliste',
            hintText: 'Ex: Courses, Séries, Activités',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _createSuperlisteForFamille(context, ref, familleId, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _createSuperlisteForFamille(context, ref, familleId, controller.text.trim());
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _createSuperliste(BuildContext context, WidgetRef ref, String nom) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.familleActiveId.isNotEmpty) {
        await ref.read(databaseServiceProvider).createSuperliste(user.familleActiveId, nom);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
            content: Text('Superliste "$nom" créée avec succès !'),
            backgroundColor: Colors.green,
          ),
          );
        }
      } else {
        throw Exception('Utilisateur non connecté ou sans famille');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createSuperlisteForFamille(BuildContext context, WidgetRef ref, String familleId, String nom) async {
    try {
      await ref.read(databaseServiceProvider).createSuperliste(familleId, nom);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Superliste "$nom" créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
  }

  Widget _buildTopActionsBar(BuildContext context) {
    final ref = this.ref;
    final user = ref.watch(currentUserProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          if (user != null) ...[
            IconButton(
              icon: Icon(Icons.logout, color: isDark ? Colors.white : Colors.black87),
              tooltip: 'Se déconnecter',
              onPressed: () => _handleLogout(context, ref),
            ),
            const SizedBox(width: 6),
            Icon(Icons.account_circle, color: isDark ? Colors.white : Colors.black87, size: 20),
            const SizedBox(width: 6),
            Text(
              user.email,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: isDark ? 'Mode clair' : 'Mode sombre',
            onPressed: () {
              final notifier = ref.read(themeModeProvider.notifier);
              notifier.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ],
      ),
    );
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
} 