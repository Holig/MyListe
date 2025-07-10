import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/historique_action.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/categorie.dart';
import '../models/famille.dart';
import 'dart:math';
import 'dart:ui';

class HistoriquePage extends ConsumerWidget {
  final String superlisteId;
  final String listeId;
  const HistoriquePage({required this.superlisteId, required this.listeId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final familleId = user?.familleActiveId ?? '';
    final familleAsync = ref.watch(databaseServiceProvider).getFamille(familleId);
    final historiqueStream = ref.watch(databaseServiceProvider).getHistoriqueActions(familleId, superlisteId, listeId);
    final categories = ref.watch(categoriesProvider(superlisteId)).value ?? [];
    final categorieMap = {for (var c in categories) c.id: c.nom};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          StreamBuilder<Famille?>(
            stream: ref.read(databaseServiceProvider).getFamille(familleId),
            builder: (context, snapshot) {
              final famille = snapshot.data;
              if (snapshot.hasData &&
                  famille != null &&
                  user != null &&
                  famille.adminIds.isNotEmpty &&
                  famille.adminIds.first == user.id) {
                return IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Supprimer l\'historique',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: const Text('Voulez-vous vraiment supprimer tout l\'historique de cette liste ?'),
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
                      await ref.read(databaseServiceProvider).deleteAllHistoriqueActions(familleId, superlisteId, listeId);
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<HistoriqueAction>>(
        stream: historiqueStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final actions = snapshot.data ?? [];
          if (actions.isEmpty) {
            return const Center(child: Text('Aucune action enregistrée pour cette liste.'));
          }
          return ListView.separated(
            itemCount: actions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final action = actions[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              // Couleur de fond selon l'utilisateur (random sur userId)
              final userHash = action.userId.hashCode;
              final rand = Random(userHash);
              Color color;
              // Génération d'une couleur pastel unique par utilisateur
              final hue = rand.nextInt(360).toDouble();
              final saturation = isDark ? 0.25 : 0.28; // faible saturation
              final lightness = isDark ? 0.28 : 0.85; // sombre ou clair
              color = HSLColor.fromAHSL(0.7, hue, saturation, lightness).toColor();
              return Container(
                color: color,
                child: ListTile(
                  leading: _buildIcon(action.type),
                  title: Text(_buildTitle(action, categorieMap)),
                  subtitle: Text('Par ${action.userId} • ${_formatDate(action.date)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Icon _buildIcon(String type) {
    switch (type) {
      case 'ajout':
        return const Icon(Icons.add, color: Colors.green);
      case 'suppression':
        return const Icon(Icons.delete, color: Colors.red);
      case 'modification':
        return const Icon(Icons.edit, color: Colors.orange);
      default:
        return const Icon(Icons.history);
    }
  }

  String _buildTitle(HistoriqueAction action, [Map<String, String>? categorieMap]) {
    switch (action.type) {
      case 'ajout':
        return 'Ajout de "${action.elementNom}"';
      case 'suppression':
        return 'Suppression de "${action.elementNom}"';
      case 'modification':
        return 'Modification de "${action.elementNom}"';
      case 'like':
        return 'Like sur "${action.elementNom}"';
      case 'unlike':
        return 'Retrait du like sur "${action.elementNom}"';
      case 'dislike':
        return 'Dislike sur "${action.elementNom}"';
      case 'undislike':
        return 'Retrait du dislike sur "${action.elementNom}"';
      case 'ajout_categorie':
        final nomCat = categorieMap?[action.nouvelleValeur ?? ''] ?? action.nouvelleValeur ?? '';
        return 'Ajout de la catégorie "$nomCat" à "${action.elementNom}"';
      case 'suppression_categorie':
        final nomCat = categorieMap?[action.ancienneValeur ?? ''] ?? action.ancienneValeur ?? '';
        return 'Suppression de la catégorie "$nomCat" de "${action.elementNom}"';
      case 'modification_categorie':
        final nomCatAvant = categorieMap?[action.ancienneValeur ?? ''] ?? action.ancienneValeur ?? '';
        final nomCatApres = categorieMap?[action.nouvelleValeur ?? ''] ?? action.nouvelleValeur ?? '';
        return 'Changement de catégorie de "${action.elementNom}" : "$nomCatAvant" → "$nomCatApres"';
      default:
        return action.type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 