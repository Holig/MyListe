import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/pages/categories_page.dart';

class AccueilPage extends ConsumerWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes types de listes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => _handleLogout(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Gérer les catégories'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Paramètres famille'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_task_rounded, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun type de liste pour le moment.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cliquez sur le bouton + pour créer votre premier type de liste !',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final branche = branches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.list_alt)),
                  title: Text(branche.nom),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go('/branche/${branche.id}');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBrancheDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Créer un type de liste',
      ),
    );
  }

  void _showCreateBrancheDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un nouveau type de liste'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom du type de liste',
            hintText: 'Ex: Courses, Séries, Activités',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _createBranche(context, ref, value.trim());
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
                _createBranche(context, ref, controller.text.trim());
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _createBranche(BuildContext context, WidgetRef ref, String nom) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.familleId.isNotEmpty) {
        await ref.read(databaseServiceProvider).createBranche(user.familleId, nom);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
            content: Text('Type de liste "$nom" créé avec succès !'),
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

  void _handleMenuAction(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'categories':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CategoriesPage(),
          ),
        );
        break;
      case 'settings':
        context.go('/famille');
        break;
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
  }
} 