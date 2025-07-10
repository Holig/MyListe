import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:my_liste/models/categorie.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../models/historique_action.dart';

class CategoriesPage extends ConsumerWidget {
  final String superlisteId;
  const CategoriesPage({required this.superlisteId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(superlisteId));
    final user = ref.watch(currentUserProvider).value;
    final familleAsync = user != null && user.familleActiveId.isNotEmpty
        ? ref.watch(databaseServiceProvider).getFamille(user.familleActiveId)
        : null;

    return familleAsync == null
        ? Scaffold(body: Center(child: Text('Chargement...')))
        : StreamBuilder(
            stream: familleAsync,
            builder: (context, snapshot) {
              final famille = snapshot.data;
              final isAdminOrOwner = famille != null && user != null && famille.adminIds.contains(user.id);
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
                  title: const Text('Gestion des catégories'),
                  actions: [
                    if (isAdminOrOwner)
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Ajouter une catégorie',
                        onPressed: () => _showAddCategoryDialog(context, ref),
                      ),
                  ],
                ),
                body: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Erreur: $err')),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucune catégorie pour le moment.',
                                style: TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Ajoutez votre première catégorie pour organiser vos listes !',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ReorderableGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      padding: const EdgeInsets.all(16),
                      children: categories.map((categorie) => _buildCategoryCard(context, ref, categorie, isAdminOrOwner)).toList(),
                      onReorder: isAdminOrOwner
                          ? (oldIndex, newIndex) => _reorderCategories(context, ref, categories, oldIndex, newIndex)
                          : (oldIndex, newIndex) {},
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, Categorie categorie, bool isAdminOrOwner) {
    return Card(
      key: ValueKey(categorie.id),
      child: InkWell(
        onTap: isAdminOrOwner ? () => _showEditCategoryDialog(context, ref, categorie) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category,
                size: 48,
                color: Colors.green[600],
              ),
              const SizedBox(height: 8),
              Text(
                categorie.nom,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Ordre: ${categorie.ordre + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final user = ref.read(currentUserProvider).value;
    final famille = user != null && user.familleActiveId.isNotEmpty
        ? ref.read(databaseServiceProvider).getFamille(user.familleActiveId)
        : null;
    // Sécurité UI : refuse si non admin
    if (famille == null) return;
    famille.first.then((fam) {
      if (fam == null || user == null || !fam.adminIds.contains(user.id)) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seuls les admins ou le propriétaire peuvent gérer les catégories.'), backgroundColor: Colors.red),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajouter une catégorie'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nom de la catégorie',
              hintText: 'Ex: Fruits, Légumes, Produits laitiers',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _addCategory(context, ref, value.trim());
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
                  _addCategory(context, ref, controller.text.trim());
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      );
    });
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Categorie categorie) {
    final controller = TextEditingController(text: categorie.nom);
    final user = ref.read(currentUserProvider).value;
    final famille = user != null && user.familleActiveId.isNotEmpty
        ? ref.read(databaseServiceProvider).getFamille(user.familleActiveId)
        : null;
    if (famille == null) return;
    famille.first.then((fam) {
      if (fam == null || user == null || !fam.adminIds.contains(user.id)) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seuls les admins ou le propriétaire peuvent gérer les catégories.'), backgroundColor: Colors.red),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modifier la catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _deleteCategory(context, ref, categorie),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _updateCategory(context, ref, categorie, controller.text.trim());
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      );
    });
  }

  void _addCategory(BuildContext context, WidgetRef ref, String nom) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.familleActiveId.isNotEmpty) {
        final famille = await ref.read(databaseServiceProvider).getFamille(user.familleActiveId).first;
        if (famille == null || user == null || !famille.adminIds.contains(user.id)) {
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seuls les admins ou le propriétaire peuvent gérer les catégories.'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        final categories = ref.read(categoriesProvider(superlisteId)).value ?? [];
        final newOrdre = categories.length;
        
        await ref.read(databaseServiceProvider).createCategorie(user.familleActiveId, superlisteId, nom, newOrdre);
        // Historique ajout catégorie (collection dédiée)
        await ref.read(databaseServiceProvider).addCategorieHistoriqueAction(
          familleId: user.familleActiveId,
          superlisteId: superlisteId,
          action: HistoriqueAction(
            id: '',
            userId: user.email,
            type: 'ajout_categorie',
            elementNom: nom,
            date: DateTime.now(),
          ),
        );
        
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Catégorie "$nom" ajoutée !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateCategory(BuildContext context, WidgetRef ref, Categorie categorie, String newNom) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.familleActiveId.isNotEmpty) {
        final famille = await ref.read(databaseServiceProvider).getFamille(user.familleActiveId).first;
        if (famille == null || user == null || !famille.adminIds.contains(user.id)) {
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seuls les admins ou le propriétaire peuvent gérer les catégories.'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        final updatedCategorie = Categorie(
          id: categorie.id,
          nom: newNom,
          ordre: categorie.ordre,
          superlisteId: superlisteId,
        );
        
        await ref.read(databaseServiceProvider).updateCategorie(user.familleActiveId, superlisteId, updatedCategorie);
        
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Catégorie modifiée !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, Categorie categorie) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "${categorie.nom}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = ref.read(currentUserProvider).value;
        if (user != null && user.familleActiveId.isNotEmpty) {
          final famille = await ref.read(databaseServiceProvider).getFamille(user.familleActiveId).first;
          if (famille == null || user == null || !famille.adminIds.contains(user.id)) {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seuls les admins ou le propriétaire peuvent gérer les catégories.'), backgroundColor: Colors.red),
              );
            }
            return;
          }
          await ref.read(databaseServiceProvider).deleteCategorie(user.familleActiveId, superlisteId, categorie.id);
          
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Catégorie supprimée !'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _reorderCategories(BuildContext context, WidgetRef ref, List<Categorie> categories, int oldIndex, int newIndex) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.familleActiveId.isNotEmpty) {
        final famille = await ref.read(databaseServiceProvider).getFamille(user.familleActiveId).first;
        if (famille == null || user == null || !famille.adminIds.contains(user.id)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seuls les admins ou le propriétaire peuvent gérer les catégories.'), backgroundColor: Colors.red),
          );
          return;
        }
        // Réorganiser la liste localement
        final reorderedCategories = List<Categorie>.from(categories);
        final item = reorderedCategories.removeAt(oldIndex);
        reorderedCategories.insert(newIndex, item);

        // Mettre à jour l'ordre dans Firestore
        await ref.read(databaseServiceProvider).updateCategoriesOrder(user.familleActiveId, superlisteId, reorderedCategories);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordre des catégories mis à jour !'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 