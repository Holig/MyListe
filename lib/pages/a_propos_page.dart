import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AProposPage extends ConsumerWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo et titre
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.list_alt,
                      size: 80,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MyListe',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Description
            const Text(
              'À propos de MyListe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'MyListe est une application collaborative qui permet aux familles de créer, partager et gérer des listes ensemble. Que ce soit pour les courses, les tâches ménagères, ou tout autre type de liste, MyListe facilite l\'organisation familiale.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Fonctionnalités principales
            const Text(
              'Fonctionnalités principales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              icon: Icons.group,
              title: 'Collaboration familiale',
              description: 'Partagez vos listes avec tous les membres de votre famille',
            ),
            _buildFeatureItem(
              icon: Icons.category,
              title: 'Organisation par catégories',
              description: 'Organisez vos éléments par catégories personnalisables',
            ),
            _buildFeatureItem(
              icon: Icons.check_circle,
              title: 'Suivi en temps réel',
              description: 'Voyez les modifications de vos listes en temps réel',
            ),
            _buildFeatureItem(
              icon: Icons.qr_code,
              title: 'Partage facile',
              description: 'Rejoignez une famille via un code ou un QR code',
            ),
            
            const SizedBox(height: 24),
            
            // Équipe de développement
            const Text(
              'Équipe de développement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Développé avec ❤️',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MyListe est développé avec Flutter et Firebase pour offrir une expérience utilisateur optimale sur tous les appareils.',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Liens utiles
            const Text(
              'Liens utiles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLinkItem(
              icon: Icons.description,
              title: 'Politique de confidentialité',
              onTap: () => _openPrivacyPolicy(context),
            ),
            _buildLinkItem(
              icon: Icons.description,
              title: 'Conditions d\'utilisation',
              onTap: () => _openTermsOfService(context),
            ),
            _buildLinkItem(
              icon: Icons.contact_support,
              title: 'Nous contacter',
              onTap: () => _openContact(context),
            ),
            
            const SizedBox(height: 32),
            
            // Copyright
            Center(
              child: Text(
                '© 2024 MyListe. Tous droits réservés.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.green[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green[600]),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    // TODO: Naviguer vers la politique de confidentialité
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Politique de confidentialité'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openTermsOfService(BuildContext context) {
    // TODO: Naviguer vers les conditions d'utilisation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conditions d\'utilisation'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openContact(BuildContext context) {
    Navigator.of(context).pushNamed('/contact');
  }
} 