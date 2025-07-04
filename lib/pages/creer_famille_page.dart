import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:go_router/go_router.dart';

class CreerFamillePage extends ConsumerStatefulWidget {
  const CreerFamillePage({super.key});

  @override
  ConsumerState<CreerFamillePage> createState() => _CreerFamillePageState();
}

class _CreerFamillePageState extends ConsumerState<CreerFamillePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomFamilleController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nomFamilleController.dispose();
    super.dispose();
  }

  Future<void> _creerFamille() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final user = authService.currentUser;

      if (user != null) {
        try {
          await dbService.createFamily(_nomFamilleController.text.trim(), user);
          // La redirection est gérée par AuthWrapper, donc pas besoin de Navigator.pop
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de la création: ${e.toString()}'))
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        // Gérer le cas où l'utilisateur est null (ne devrait pas arriver ici)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: utilisateur non connecté.'))
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une nouvelle famille'),
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
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.group_add_outlined, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 24),
                Text(
                  'Donnez un nom à votre famille',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous pourrez inviter des membres plus tard.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nomFamilleController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la famille',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom pour la famille.';
                    }
                    if (value.length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
                    onPressed: _creerFamille,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer la famille'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 