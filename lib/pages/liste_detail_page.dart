import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/models/liste.dart';
import 'package:my_liste/models/tag.dart';
import 'package:my_liste/models/categorie.dart';
import 'package:uuid/uuid.dart';
import 'package:my_liste/services/auth_service.dart';

class ListeDetailPage extends ConsumerWidget {
  final String superlisteId;
  final String listeId;

  const ListeDetailPage({
    required this.superlisteId,
    required this.listeId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listeAsync = ref.watch(listeProvider((superlisteId, listeId)));
    final categoriesAsync = ref.watch(categoriesProvider(superlisteId));
    final tagsAsync = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/superliste/$superlisteId');
            }
          },
        ),
        title: listeAsync.when(
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('Erreur'),
          data: (liste) => Text(liste?.titre ?? 'Liste'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () {
              // TODO: Naviguer vers l'historique
            },
          ),
        ],
      ),
      body: listeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (liste) {
          if (liste == null) {
            return const Center(child: Text('Liste non trouvée'));
          }

          return Column(
            children: [
              // Barre de recherche et ajout d'éléments
              _buildSearchBar(context, ref, liste),
              // Liste des éléments groupés par catégorie
              Expanded(
                child: _buildElementsList(context, ref, liste),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, Liste liste) {
    final user = ref.read(currentUserProvider).value;
    final familleId = user?.familleActiveId ?? '';
    final Future<List<Tag>> futureSuggestions =
        (familleId.isNotEmpty)
            ? ref.read(databaseServiceProvider).getAllElementsOfSuperliste(familleId, superlisteId)
            : Future.value([]);

    String? lastSelected;
    final textController = TextEditingController();

    return FutureBuilder<List<Tag>>(
      future: futureSuggestions,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];
        final uniqueSuggestions = suggestions
            .map((e) => e.nom.trim())
            .where((nom) => nom.isNotEmpty)
            .toSet()
            .toList();
        // Associer à chaque nom la dernière catégorie utilisée
        final Map<String, String> lastCategorieByNom = {};
        for (final tag in suggestions) {
          lastCategorieByNom[tag.nom.trim()] = tag.categorieId;
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[50],
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return uniqueSuggestions.where((option) =>
                        option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  fieldViewBuilder: (context, _, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ajouter un élément...',
                        prefixIcon: const Icon(Icons.add),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                      ),
                      onSubmitted: (value) {
                        final toAdd = lastSelected ?? value.trim();
                        if (toAdd.isNotEmpty) {
                          final catId = lastCategorieByNom[toAdd] ?? '';
                          _addElement(context, ref, liste, toAdd, catId);
                          textController.clear();
                          lastSelected = null;
                        }
                      },
                      onChanged: (_) {
                        lastSelected = null;
                      },
                    );
                  },
                  onSelected: (String selection) {
                    final catId = lastCategorieByNom[selection] ?? '';
                    _addElement(context, ref, liste, selection, catId);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Vide le champ après sélection
                      final field = FocusScope.of(context).focusedChild?.context?.widget;
                      if (field is TextField) {
                        field.controller?.clear();
                      }
                    });
                    lastSelected = null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final toAdd = lastSelected ?? textController.text.trim();
                  if (toAdd.isNotEmpty) {
                    final catId = lastCategorieByNom[toAdd] ?? '';
                    _addElement(context, ref, liste, toAdd, catId);
                    textController.clear();
                    lastSelected = null;
                  }
                },
                icon: const Icon(Icons.add_circle),
                color: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElementsList(BuildContext context, WidgetRef ref, Liste liste) {
    final categoriesAsync = ref.watch(categoriesProvider(superlisteId));
    
    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (categories) {
        // Grouper les éléments par catégorie
        final elementsByCategory = <String, List<Tag>>{};
        
        for (final element in liste.elements) {
          final categorieId = element.categorieId.isNotEmpty 
              ? element.categorieId 
              : 'sans_categorie';
          elementsByCategory.putIfAbsent(categorieId, () => []).add(element);
        }

        // Trier les catégories par ordre
        final sortedCategories = categories.toList()
          ..sort((a, b) => a.ordre.compareTo(b.ordre));

        return ListView.builder(
          itemCount: sortedCategories.length + (elementsByCategory.containsKey('sans_categorie') ? 1 : 0),
          itemBuilder: (context, index) {
            Categorie? categorie;
            if (index < sortedCategories.length) {
              categorie = sortedCategories[index];
            } else if (elementsByCategory.containsKey('sans_categorie')) {
              // Catégorie "sans catégorie" à la fin
              categorie = null;
            }

            final elements = elementsByCategory[categorie?.id ?? 'sans_categorie'] ?? [];
            
            if (elements.isEmpty) return const SizedBox.shrink();

            return _buildCategorySection(context, ref, liste, categorie, elements);
          },
        );
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    Categorie? categorie,
    List<Tag> elements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de catégorie
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[100],
          child: Text(
            categorie?.nom ?? 'Sans catégorie',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[100]
                  : Colors.black,
            ),
          ),
        ),
        
        // Éléments de la catégorie
        ...elements.map((element) => _buildElementCard(context, ref, liste, element)),
      ],
    );
  }

  Widget _buildElementCard(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    Tag element,
  ) {
    final isLiked = element.like;
    final isDisliked = element.dislike;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isLiked
          ? (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B5E20) // vert foncé
              : Colors.green[50])
          : isDisliked
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFB71C1C) // rouge foncé
                  : Colors.red[50])
              : null,
      child: ListTile(
        title: Text(
          element.nom,
          style: TextStyle(
            decoration: isLiked ? TextDecoration.lineThrough : null,
            color: (Theme.of(context).brightness == Brightness.dark && (isLiked || isDisliked))
                ? Colors.white
                : isLiked
                    ? Colors.grey[600]
                    : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Like
            IconButton(
              onPressed: () => _toggleLike(context, ref, liste, element),
              icon: Icon(
                Icons.thumb_up,
                color: isLiked ? Colors.green : Colors.grey,
              ),
              tooltip: 'Trouvé',
            ),
            // Bouton Dislike
            IconButton(
              onPressed: () => _toggleDislike(context, ref, liste, element),
              icon: Icon(
                Icons.thumb_down,
                color: isDisliked ? Colors.red : Colors.grey,
              ),
              tooltip: 'Non trouvé',
            ),
            // Menu contextuel
            PopupMenuButton<String>(
              onSelected: (value) => _handleElementAction(context, ref, liste, element, value),
              itemBuilder: (context) => [
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
          ],
        ),
      ),
    );
  }

  void _addElement(BuildContext context, WidgetRef ref, Liste liste, String nom, [String? categorieId]) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null || user.familleActiveId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté ou sans famille'), backgroundColor: Colors.red),
        );
        return;
      }
      final uuid = const Uuid();
      final newElement = Tag(
        id: uuid.v4(),
        nom: nom,
        categorieId: categorieId ?? '',
      );
      await ref.read(databaseServiceProvider).addElementToListe(
        user.familleActiveId,
        superlisteId,
        listeId,
        newElement,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Élément "$nom" ajouté !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleLike(BuildContext context, WidgetRef ref, Liste liste, Tag element) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null || user.familleActiveId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté ou sans famille'), backgroundColor: Colors.red),
        );
        return;
      }
      final updatedElement = Tag(
        id: element.id,
        nom: element.nom,
        categorieId: element.categorieId,
        like: !element.like,
        dislike: false, // Désactiver dislike si on like
      );
      await ref.read(databaseServiceProvider).updateElementInListe(
        user.familleActiveId,
        superlisteId,
        listeId,
        updatedElement,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleDislike(BuildContext context, WidgetRef ref, Liste liste, Tag element) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null || user.familleActiveId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté ou sans famille'), backgroundColor: Colors.red),
        );
        return;
      }
      final updatedElement = Tag(
        id: element.id,
        nom: element.nom,
        categorieId: element.categorieId,
        like: false, // Désactiver like si on dislike
        dislike: !element.dislike,
      );
      await ref.read(databaseServiceProvider).updateElementInListe(
        user.familleActiveId,
        superlisteId,
        listeId,
        updatedElement,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleElementAction(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    Tag element,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        _showEditElementDialog(context, ref, liste, element);
        break;
      case 'delete':
        await _deleteElement(context, ref, liste, element);
        break;
    }
  }

  void _showEditElementDialog(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    Tag element,
  ) {
    final controller = TextEditingController(text: element.nom);
    final categories = ref.read(categoriesProvider(superlisteId)).value ?? [];
    String selectedCategorieId = element.categorieId;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier l\'élément'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'élément',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategorieId.isNotEmpty ? selectedCategorieId : null,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Sans catégorie'),
                  ),
                  ...categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.nom),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategorieId = value ?? '';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _updateElementWithCategorie(context, ref, liste, element, controller.text.trim(), selectedCategorieId);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateElementWithCategorie(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    Tag element,
    String newNom,
    String newCategorieId,
  ) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null || user.familleActiveId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté ou sans famille'), backgroundColor: Colors.red),
        );
        return;
      }
      final updatedElement = Tag(
        id: element.id,
        nom: newNom,
        categorieId: newCategorieId,
        like: element.like,
        dislike: element.dislike,
      );
      await ref.read(databaseServiceProvider).updateElementInListe(
        user.familleActiveId,
        superlisteId,
        listeId,
        updatedElement,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Élément modifié !'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteElement(
    BuildContext context,
    WidgetRef ref,
    Liste liste,
    Tag element,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || user.familleActiveId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecté ou sans famille'), backgroundColor: Colors.red),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${element.nom}" ?',
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
        await ref.read(databaseServiceProvider).removeElementFromListe(
          user.familleActiveId,
          superlisteId,
          listeId,
          element.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Élément supprimé !'), backgroundColor: Colors.red),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Provider pour récupérer une liste spécifique
final listeProvider = StreamProvider.family<Liste?, (String, String)>((ref, params) {
  final (superlisteId, listeId) = params;
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(databaseServiceProvider).getListe(user.familleActiveId, superlisteId, listeId);
}); 