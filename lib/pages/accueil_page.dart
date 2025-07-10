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

class AccueilPage extends ConsumerStatefulWidget {
  const AccueilPage({super.key});

  @override
  ConsumerState<AccueilPage> createState() => _AccueilPageState();
}

final tabIndexProvider = StateProvider<int>((ref) => 0);

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
        title: const Text('MyListe'),
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
          Consumer(
            builder: (context, ref, _) {
              final familleAsync = ref.watch(familleProvider);
              return familleAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (famille) {
                  if (famille == null) return const SizedBox.shrink();
                  return Container(
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
                    child: Text(
                      'Famille "${famille.nom}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
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
      floatingActionButton: currentIndex == 0 ? FloatingActionButton(
        onPressed: () => _showCreateSuperlisteDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Créer une superliste',
      ) : null,
    );
  }

  Widget _buildSuperlistesTab() {
    final superlistesAsync = ref.watch(superlistesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Sous-AppBar pour afficher le nom de la superliste actuelle
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
        // Contenu des superlistes
        Expanded(
          child: superlistesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
            data: (superlistes) {
              if (superlistes.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_task_rounded, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune superliste pour le moment.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Cliquez sur le bouton + pour créer votre première superliste !',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: superlistes.length,
                itemBuilder: (context, index) {
                  final superliste = superlistes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.list_alt)),
                      title: Text(superliste.nom),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.go('/superliste/${superliste.id}');
                      },
                    ),
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
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
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