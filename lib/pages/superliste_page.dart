import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_liste/models/superliste.dart';
import 'package:my_liste/models/liste.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/pages/categories_page.dart';
import 'package:intl/intl.dart';

class SuperlistePage extends ConsumerWidget {
  final String id;
  const SuperlistePage({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final superlisteAsync = ref.watch(superlisteProvider(id));
    final listesAsync = ref.watch(listesProvider(id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accueil'),
        ),
        title: const Text('Superliste'),
        actions: [
        ],
      ),
      body: Column(
        children: [
          // Sous-AppBar pour afficher le nom de la superliste
          superlisteAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Chargement...'),
                ],
              ),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border(bottom: BorderSide(color: Colors.red[300]!)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Erreur de chargement'),
                ],
              ),
            ),
            data: (superliste) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      superliste?.nom ?? 'Superliste',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (superliste != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Renommer la superliste',
                      onPressed: () => _showEditSuperlisteNameDialog(context, ref, superliste),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Créer une liste',
                    onPressed: () => _showCreateListeDialog(context, ref),
                  ),
                ],
              ),
            ),
          ),
          // Contenu des listes
          Expanded(
            child: listesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur: $err')),
              data: (listes) {
                final listesActives = listes.where((liste) => !liste.fermee).toList();
                final listesFermees = listes.where((liste) => liste.fermee).toList();

                return Column(
                  children: [
                    // Section des listes actives
                    Expanded(
                      flex: 2,
                      child: _buildListesSection(
                        context,
                        ref,
                        'Listes actives',
                        listesActives,
                        false,
                      ),
                    ),
                    
                    // Séparateur
                    if (listesFermees.isNotEmpty)
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    
                    // Section des listes fermées
                    if (listesFermees.isNotEmpty)
                      Expanded(
                        flex: 1,
                        child: _buildListesSection(
                          context,
                          ref,
                          'Listes fermées',
                          listesFermees,
                          true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.category),
            label: const Text('Gérer les catégories'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showCategoriesDialog(context, ref),
          ),
        ),
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoriesPage(superlisteId: id),
      ),
    );
  }

  Widget _buildListesSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Liste> listes,
    bool isClosed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isClosed ? Colors.grey[600] : null,
            ),
          ),
        ),
        Expanded(
          child: listes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isClosed ? Icons.archive : Icons.list_alt,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isClosed
                              ? 'Aucune liste fermée'
                              : 'Aucune liste active',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: listes.length,
                  itemBuilder: (context, index) {
                    final liste = listes[index];
                    return _buildListeCard(context, ref, liste, isClosed);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListeCard(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    bool isClosed,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formattedDate = dateFormat.format(liste.date);
    final elementCount = liste.elements.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isDark ? Theme.of(context).colorScheme.surface : isClosed ? Colors.grey[100] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? Theme.of(context).colorScheme.surface : isClosed ? Colors.grey[400] : Colors.green,
          child: Icon(
            isClosed ? Icons.archive : Icons.list_alt,
            color: Colors.white,
          ),
        ),
        title: Text(
          liste.titre,
          style: TextStyle(
            color: isDark ? Theme.of(context).colorScheme.onSurface : isClosed ? Colors.grey[600] : null,
            decoration: isClosed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créée le $formattedDate',
              style: TextStyle(
                color: isDark ? Theme.of(context).colorScheme.onSurface : isClosed ? Colors.grey[500] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (elementCount > 0)
              Text(
                '$elementCount élément${elementCount > 1 ? 's' : ''}',
                style: TextStyle(
                  color: isDark ? Theme.of(context).colorScheme.onSurface : isClosed ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleListeAction(context, ref, liste, value),
          itemBuilder: (context) => [
            if (!isClosed) ...[
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Fermer'),
                  ],
                ),
              ),
            ] else ...[
              const PopupMenuItem(
                value: 'reopen',
                child: Row(
                  children: [
                    Icon(Icons.unarchive),
                    SizedBox(width: 8),
                    Text('Rouvrir'),
                  ],
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 8),
                  Text('Dupliquer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          context.go('/liste/$id/${liste.id}');
        },
      ),
    );
  }

  void _showCreateListeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une nouvelle liste'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Titre de la liste',
            hintText: 'Ex: Courses semaine 25',
            fillColor: Theme.of(context).colorScheme.surface,
            filled: true,
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _createListe(context, ref, value.trim());
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
                _createListe(context, ref, controller.text.trim());
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _createListe(BuildContext context, WidgetRef ref, String titre) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.familleActiveId.isNotEmpty) {
        await ref.read(databaseServiceProvider).createListe(user.familleActiveId, id, titre);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Liste "$titre" créée avec succès !'),
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

  void _handleListeAction(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    String action,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || user.familleActiveId.isEmpty) {
      _showSnackBar(context, 'Utilisateur non connecté ou sans famille', Colors.red);
      return;
    }
    try {
      switch (action) {
        case 'edit':
          print('Edit liste: ${liste.titre}');
          break;
        case 'close':
          await ref.read(databaseServiceProvider).updateListeStatus(
                user.familleActiveId,
                liste.superlisteId,
                liste.id,
                true,
              );
          _showSnackBar(context, 'Liste fermée avec succès !', Colors.orange);
          break;
        case 'reopen':
          await ref.read(databaseServiceProvider).updateListeStatus(
                user.familleActiveId,
                liste.superlisteId,
                liste.id,
                false,
              );
          _showSnackBar(context, 'Liste rouverte avec succès !', Colors.green);
          break;
        case 'duplicate':
          await _duplicateListe(context, ref, liste);
          break;
        case 'delete':
          await _deleteListe(context, ref, liste);
          break;
      }
    } catch (e) {
      _showSnackBar(context, 'Erreur: $e', Colors.red);
    }
  }

  Future<void> _duplicateListe(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || user.familleActiveId.isEmpty) {
      _showSnackBar(context, 'Utilisateur non connecté ou sans famille', Colors.red);
      return;
    }
    final newTitre = '${liste.titre} (copie)';
    // Ne dupliquer que les éléments non likés
    final elementsADupliquer = liste.elements.where((e) => !e.like).toList();
    await ref.read(databaseServiceProvider).createListe(
      user.familleActiveId,
      liste.superlisteId,
      newTitre,
      elements: elementsADupliquer,
    );
    _showSnackBar(context, 'Liste dupliquée avec succès !', Colors.blue);
  }

  Future<void> _deleteListe(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || user.familleActiveId.isEmpty) {
      _showSnackBar(context, 'Utilisateur non connecté ou sans famille', Colors.red);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la liste "${liste.titre}" ?\n\nCette action est irréversible.',
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
      await ref.read(databaseServiceProvider).deleteListe(user.familleActiveId, liste.superlisteId, liste.id);
      _showSnackBar(context, 'Liste supprimée !', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _showEditSuperlisteNameDialog(BuildContext context, WidgetRef ref, Superliste superliste) {
    final controller = TextEditingController(text: superliste.nom);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la superliste'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom de la superliste',
          ),
          autofocus: true,
          onSubmitted: (value) async {
            if (value.trim().isNotEmpty) {
              await _updateSuperlisteName(context, ref, superliste, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _updateSuperlisteName(context, ref, superliste, controller.text.trim());
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSuperlisteName(BuildContext context, WidgetRef ref, Superliste superliste, String nouveauNom) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.familleActiveId.isNotEmpty) {
        await ref.read(databaseServiceProvider).updateSuperlisteName(user.familleActiveId, superliste.id, nouveauNom);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Superliste renommée !'),
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
            content: Text('Erreur lors du renommage : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 

 