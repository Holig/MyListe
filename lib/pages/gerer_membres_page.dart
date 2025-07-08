import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_liste/models/famille.dart';
import 'package:my_liste/models/utilisateur.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class GererMembresPage extends ConsumerWidget {
  const GererMembresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null || user.familleActiveId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Aucune famille active')),
      );
    }
    final familleStream = ref.watch(databaseServiceProvider).getFamille(user.familleActiveId);
    return StreamBuilder<Famille?>(
      stream: familleStream,
      builder: (context, snapshot) {
        final famille = snapshot.data;
        if (famille == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gérer les membres'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: 56,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          body: FutureBuilder<List<Utilisateur?>> (
            future: Future.wait(famille.membresIds.map((uid) => ref.read(databaseServiceProvider).getUser(uid))),
            builder: (context, snapshot) {
              final membres = snapshot.data?.where((m) => m != null).cast<Utilisateur>().toList() ?? [];
              final isAdmin = famille.adminIds.contains(user.id);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...membres.map((membre) {
                    final isOwner = famille.adminIds.isNotEmpty && famille.adminIds.first == membre.id;
                    final isCurrentUser = membre.id == user.id;
                    String roleLabel = isOwner
                        ? 'Propriétaire'
                        : isAdmin
                            ? 'Admin'
                            : 'Membre';
                    Color? roleColor = isOwner
                        ? Colors.deepPurple
                        : isAdmin
                            ? Colors.green
                            : null;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isOwner
                              ? Icons.verified
                              : isAdmin
                                  ? Icons.verified_user
                                  : Icons.person,
                          color: roleColor,
                        ),
                        title: Text(membre.nom ?? membre.email),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(membre.email),
                            Text(roleLabel, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Promotion/rétrogradation (admin seulement, sauf propriétaire)
                            if (famille.adminIds.contains(user.id) && !isCurrentUser && !isOwner)
                              isAdmin
                                  ? IconButton(
                                      icon: const Icon(Icons.arrow_downward, color: Colors.orange),
                                      tooltip: 'Rétrograder en membre',
                                      onPressed: () async {
                                        try {
                                          await ref.read(databaseServiceProvider).demoteFromAdmin(famille.id, membre.id);
                                          print('Rétrogradation réussie pour ${membre.email}');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('"${membre.email}" est maintenant membre.'), backgroundColor: Colors.green),
                                            );
                                          }
                                        } catch (e) {
                                          print('Erreur rétrogradation: $e');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Erreur lors de la rétrogradation : $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.arrow_upward, color: Colors.blue),
                                      tooltip: 'Promouvoir en admin',
                                      onPressed: () async {
                                        await ref.read(databaseServiceProvider).promoteToAdmin(famille.id, membre.id);
                                      },
                                    ),
                            // Suppression (admin seulement, sauf propriétaire et soi-même)
                            if (famille.adminIds.contains(user.id) && !isCurrentUser && !isOwner)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                tooltip: 'Supprimer ce membre',
                                onPressed: () async {
                                  await _removeMember(context, ref, famille, membre);
                                },
                              ),
                            // Quitter la famille (pour soi-même)
                            if (isCurrentUser && user.famillesIds.length > 1)
                              IconButton(
                                icon: const Icon(Icons.exit_to_app),
                                tooltip: 'Quitter la famille',
                                onPressed: () async {
                                  await ref.read(databaseServiceProvider).quitFamily(famille.id, auth.FirebaseAuth.instance.currentUser!);
                                  context.go('/accueil');
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (membres.isEmpty)
                    const Center(child: Text('Aucun membre dans cette famille.')),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, Famille famille, Utilisateur membre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce membre ?'),
        content: Text('Voulez-vous vraiment supprimer ${membre.nom ?? membre.email} de la famille ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      // Retirer le membre de la famille
      await ref.read(databaseServiceProvider).removeMember(famille.id, membre.id);
      // Retirer la famille de l'utilisateur
      await ref.read(databaseServiceProvider).quitFamily(famille.id, auth.FirebaseAuth.instance.currentUser!);
    }
  }
} 