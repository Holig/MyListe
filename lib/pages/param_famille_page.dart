import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:my_liste/pages/categories_page.dart';
import 'package:my_liste/models/famille.dart';
import 'package:go_router/go_router.dart';

class ParamFamillePage extends ConsumerWidget {
  const ParamFamillePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final familleAsync = ref.watch(familleProvider);

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
        title: const Text('Paramètres de la famille'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (user) {
          if (user == null || user.familleId.isEmpty) {
            return const Center(
              child: Text('Aucune famille trouvée'),
            );
          }

          return familleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
            data: (famille) {
              if (famille == null) {
                return const Center(child: Text('Famille non trouvée'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations de la famille
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Famille: ${famille.nom}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Créée le ${_formatDate(famille.dateCreation)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${famille.membresIds.length} membre${famille.membresIds.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Code d'invitation
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Code d\'invitation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      famille.codeInvitation.isNotEmpty 
                                          ? famille.codeInvitation 
                                          : 'Génération...',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _copyToClipboard(context, famille.codeInvitation),
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copier le code',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Partagez ce code avec les membres de votre famille pour qu\'ils puissent rejoindre.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // QR Code
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QR Code de partage',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: QrImageView(
                                  data: famille.codeInvitation.isNotEmpty 
                                      ? famille.codeInvitation 
                                      : 'placeholder',
                                  version: QrVersions.auto,
                                  size: 200.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scannez ce QR code pour rejoindre rapidement la famille.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Actions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.people),
                              title: const Text('Gérer les membres'),
                              subtitle: const Text('Ajouter ou supprimer des membres'),
                              onTap: () {
                                // TODO: Naviguer vers la gestion des membres
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.category),
                              title: const Text('Gérer les catégories'),
                              subtitle: const Text('Organiser vos listes'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const CategoriesPage(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.settings),
                              title: const Text('Paramètres avancés'),
                              subtitle: const Text('Configuration de la famille'),
                              onTap: () {
                                // TODO: Naviguer vers les paramètres avancés
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    // TODO: Implémenter la copie dans le presse-papiers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papiers !'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Provider pour récupérer la famille de l'utilisateur actuel
final familleProvider = StreamProvider<Famille?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getFamille(user.familleId);
  }
  return Stream.value(null);
}); 