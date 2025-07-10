import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:my_liste/pages/categories_page.dart';
import 'package:my_liste/models/famille.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:my_liste/pages/gerer_membres_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// Ajout d'un provider pour forcer le rafraîchissement
final settingsRefreshProvider = StateProvider<int>((ref) => 0);

// Palette de dégradés par défaut
const List<List<String>> defaultGradients = [
  ['#8e2de2', '#4a00e0'], // Violet → Bleu
  ['#ff9966', '#ff5e62'], // Orange → Jaune
  ['#11998e', '#38ef7d'], // Vert → Turquoise
  ['#f953c6', '#b91d73'], // Rose → Rouge
  ['#43cea2', '#185a9d'], // Bleu ciel → Bleu foncé
];

Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class ParamFamillePage extends ConsumerWidget {
  const ParamFamillePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final familleAsync = ref.watch(familleProvider);
    // Ajout : écoute du provider de refresh pour forcer le rebuild
    ref.watch(settingsRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de la famille'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (user) {
          if (user == null || user.famillesIds.isEmpty) {
            return Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Créer une nouvelle famille'),
                onPressed: () => context.push('/creer-famille'),
              ),
            );
          }

          // Provider pour récupérer toutes les familles de l'utilisateur
          final famillesFuture = Future.wait(user.famillesIds.map((familleId) =>
            ref.read(databaseServiceProvider).getFamille(familleId).first
          ));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Mes familles
                FutureBuilder<List<Famille?>> (
                  future: famillesFuture,
                  builder: (context, snapshot) {
                    final familles = snapshot.data?.where((f) => f != null).cast<Famille>().toList() ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mes familles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...familles.map((fam) => fam.id == user.familleActiveId
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    hexToColor(fam.gradientColor1),
                                    hexToColor(fam.gradientColor2),
                                  ],
                                ),
                              ),
                              child: ListTile(
                                title: Text(fam.nom, style: const TextStyle(color: Colors.white)),
                                subtitle: Text('${fam.membresIds.length} membre${fam.membresIds.length > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white70)),
                                leading: const Icon(Icons.check_circle, color: Colors.white),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  tooltip: 'Personnaliser le dégradé',
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (context) => _GradientPickerDialog(famille: fam, ref: ref),
                                    );
                                    ref.read(settingsRefreshProvider.notifier).state++;
                                  },
                                ),
                              ),
                            )
                          : Card(
                              child: ListTile(
                                title: Text(fam.nom),
                                subtitle: Text('${fam.membresIds.length} membre${fam.membresIds.length > 1 ? 's' : ''}'),
                                leading: const Icon(Icons.group),
                                trailing: fam.id != user.familleActiveId
                                  ? IconButton(
                                      icon: const Icon(Icons.visibility),
                                      tooltip: 'Afficher cette famille',
                                      onPressed: () async {
                                        await ref.read(databaseServiceProvider).setActiveFamily(fam.id, auth.FirebaseAuth.instance.currentUser!);
                                        ref.read(settingsRefreshProvider.notifier).state++;
                                      },
                                    )
                                  : null,
                              ),
                            )
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Créer une famille'),
                              onPressed: () => context.push('/creer-famille'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.group_add),
                              label: const Text('Rejoindre une famille'),
                              onPressed: () => context.push('/rejoindre-famille'),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        // Ajout du widget Gestion de la famille pour la famille active
                        if (user.familleActiveId.isNotEmpty)
                          Consumer(
                            builder: (context, ref, _) {
                              final familleAsync = ref.watch(familleProvider);
                              return familleAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Center(child: Text('Erreur: $err')),
                                data: (famille) {
                                  if (famille == null) {
                                    return const Center(child: Text('Famille non trouvée'));
                                  }
                                  final invitationLink = famille.codeInvitation.isNotEmpty
                                    ? _getJoinFamilyUrl(famille.codeInvitation)
                                    : '';
                                  return Card(
                                    margin: const EdgeInsets.only(top: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Titre dynamique pour la gestion de la famille
                                          Text('Gestion de la famille ${famille.nom}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.refresh),
                                                label: const Text('Générer un code'),
                                                onPressed: () => _generateCode(context, ref, famille.id),
                                              ),
                                              const SizedBox(width: 8),
                                              if (invitationLink.isNotEmpty)
                                                OutlinedButton.icon(
                                                  icon: const Icon(Icons.copy),
                                                  label: const Text('Copier le lien'),
                                                  onPressed: () => _copyToClipboard(context, invitationLink),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          if (invitationLink.isNotEmpty)
                                            Row(
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                                    return QrImageView(
                                                      data: invitationLink,
                                                      version: QrVersions.auto,
                                                      size: 100.0,
                                                      backgroundColor: isDark ? Colors.white : Colors.transparent,
                                                      foregroundColor: isDark ? Colors.black : Colors.black,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SelectableText(invitationLink, style: const TextStyle(fontSize: 14)),
                                                      const SizedBox(height: 8),
                                                      OutlinedButton.icon(
                                                        icon: const Icon(Icons.share),
                                                        label: const Text('Partager le lien'),
                                                        onPressed: () async {
                                                          await Share.share(invitationLink);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.group),
                                            label: const Text('Gérer les membres'),
                                            onPressed: () => context.push('/gerer-membres'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papiers !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateCode(BuildContext context, WidgetRef ref, String familleId) async {
    try {
      await ref.read(databaseServiceProvider).generateInvitationCode(familleId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code d\'invitation généré avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Ajout de la fonction utilitaire pour générer le lien dynamiquement
  String _getJoinFamilyUrl(String code) {
    if (kIsWeb) {
      final origin = html.window.location.origin;
      return '${origin}/join?family=${code}';
    } else {
      // Pour mobile, adapter selon le schéma de deep link
      return 'my_liste://join?family=${code}';
    }
  }
}

// Provider pour récupérer la famille de l'utilisateur actuel
final familleProvider = StreamProvider<Famille?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.familleActiveId.isNotEmpty) {
    return ref.watch(databaseServiceProvider).getFamille(user.familleActiveId);
  }
  return Stream.value(null);
});

// Ajout du widget de sélection de dégradé
class _GradientPickerDialog extends StatefulWidget {
  final Famille famille;
  final WidgetRef ref;
  const _GradientPickerDialog({required this.famille, required this.ref});

  @override
  State<_GradientPickerDialog> createState() => _GradientPickerDialogState();
}

class _GradientPickerDialogState extends State<_GradientPickerDialog> {
  List<List<String>> gradients = List.from(defaultGradients);
  List<List<String>> customGradients = [];
  String paletteType = 'random';

  Color customColor1 = const Color(0xFF8e2de2);
  Color customColor2 = const Color(0xFF4a00e0);

  @override
  void initState() {
    super.initState();
    paletteType = widget.famille.paletteType ?? 'random';
    if (widget.famille.customGradients != null) {
      customGradients = List.from(widget.famille.customGradients!);
    }
  }

  List<String> _generateRandomGradient() {
    Color pastel1 = HSLColor.fromAHSL(1, (360 * (0.2 + 0.6 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)), 0.5, 0.8).toColor();
    Color pastel2 = HSLColor.fromAHSL(1, (360 * (0.2 + 0.6 * ((DateTime.now().millisecondsSinceEpoch + 333) % 1000) / 1000)), 0.5, 0.8).toColor();
    String hex1 = '#${pastel1.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    String hex2 = '#${pastel2.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    return [hex1, hex2];
  }

  void _addCustomGradient() {
    setState(() {
      customGradients.add([
        '#${customColor1.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        '#${customColor2.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      ]);
    });
    widget.ref.read(databaseServiceProvider).updateFamilyCustomGradients(widget.famille.id, customGradients);
  }

  void _removeCustomGradient(int index) {
    setState(() {
      customGradients.removeAt(index);
    });
    widget.ref.read(databaseServiceProvider).updateFamilyCustomGradients(widget.famille.id, customGradients);
  }

  void _removeRandomGradient(int index) {
    setState(() {
      gradients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un dégradé'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dégradés aléatoires'),
                Switch(
                  value: paletteType == 'custom',
                  onChanged: (val) async {
                    setState(() {
                      paletteType = val ? 'custom' : 'random';
                    });
                    await widget.ref.read(databaseServiceProvider).updateFamilyPaletteType(widget.famille.id, paletteType);
                  },
                ),
                const Text('Palette personnalisée'),
              ],
            ),
            const SizedBox(height: 12),
            if (paletteType == 'random') ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...gradients.asMap().entries.map((entry) {
                    final i = entry.key;
                    final g = entry.value;
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await widget.ref.read(databaseServiceProvider).updateFamilyGradient(
                              widget.famille.id, g[0], g[1],
                            );
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 80,
                            height: 50,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [hexToColor(g[0]), hexToColor(g[1])],
                              ),
                              border: Border.all(
                                color: widget.famille.gradientColor1 == g[0] && widget.famille.gradientColor2 == g[1]
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => _removeRandomGradient(i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Bouton pour ajouter un dégradé aléatoire
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        gradients.add(_generateRandomGradient());
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (paletteType == 'custom') ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...customGradients.asMap().entries.map((entry) {
                    final i = entry.key;
                    final g = entry.value;
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await widget.ref.read(databaseServiceProvider).updateFamilyGradient(
                              widget.famille.id, g[0], g[1],
                            );
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 80,
                            height: 50,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [hexToColor(g[0]), hexToColor(g[1])],
                              ),
                              border: Border.all(
                                color: widget.famille.gradientColor1 == g[0] && widget.famille.gradientColor2 == g[1]
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => _removeCustomGradient(i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text('Couleur 1'),
                      GestureDetector(
                        onTap: () async {
                          Color? picked = await showDialog<Color>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Choisir la couleur 1'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: customColor1,
                                  onColorChanged: (color) => customColor1 = color,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(customColor1),
                                  child: const Text('Valider'),
                                ),
                              ],
                            ),
                          );
                          if (picked != null) setState(() => customColor1 = picked);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: customColor1,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      const Text('Couleur 2'),
                      GestureDetector(
                        onTap: () async {
                          Color? picked = await showDialog<Color>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Choisir la couleur 2'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: customColor2,
                                  onColorChanged: (color) => customColor2 = color,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(customColor2),
                                  child: const Text('Valider'),
                                ),
                              ],
                            ),
                          );
                          if (picked != null) setState(() => customColor2 = picked);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: customColor2,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: _addCustomGradient,
                    child: const Text('Ajouter à la palette'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
} 