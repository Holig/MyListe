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
import 'package:my_liste/pages/param_notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
                // Ajoute une ligne de titre stylée avec icône pour 'Paramètres de la famille' en haut de la page
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.grey[100],
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Paramètres de la famille',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Section Mes familles
                FutureBuilder<List<Famille?>> (
                  future: famillesFuture,
                  builder: (context, snapshot) {
                    final familles = snapshot.data?.where((f) => f != null).cast<Famille>().toList() ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.family_restroom, size: 22),
                            const SizedBox(width: 8),
                            const Text('Mes familles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
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
                                  tooltip: 'Renommer ou personnaliser',
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => _EditFamilyDialog(famille: fam, ref: ref),
                                    );
                                    if (result == true) {
                                      ref.read(settingsRefreshProvider.notifier).state++;
                                    }
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
                                loading: () => const Text('Chargement famille active...'),
                                error: (err, stack) => Text('Erreur famille active : $err'),
                                data: (famille) {
                                  if (famille == null) {
                                    return const Text('Famille active non trouvée');
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
                                          const SizedBox(height: 24),
                                          // Section Notifications dédiée
                                          // Section notifications optimisée
                                          NotificationPreferencesWidget(userId: user.id, familleId: famille.id),
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
  final String initialColor1;
  final String initialColor2;
  final Function(String, String) onGradientChanged;
  final bool isDialog;
  const _GradientPickerDialog({
    required this.famille,
    required this.ref,
    required this.initialColor1,
    required this.initialColor2,
    required this.onGradientChanged,
    this.isDialog = true,
  });

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
    customColor1 = hexToColor(widget.initialColor1);
    customColor2 = hexToColor(widget.initialColor2);
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
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
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
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 220),
                    child: ElevatedButton(
                      onPressed: _addCustomGradient,
                      child: const Text('Ajouter à la palette'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Ajouter le widget _EditFamilyDialog
class _EditFamilyDialog extends StatefulWidget {
  final Famille famille;
  final WidgetRef ref;
  const _EditFamilyDialog({required this.famille, required this.ref});

  @override
  State<_EditFamilyDialog> createState() => _EditFamilyDialogState();
}

class _EditFamilyDialogState extends State<_EditFamilyDialog> {
  late TextEditingController _controller;
  late String _color1;
  late String _color2;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.famille.nom);
    _color1 = widget.famille.gradientColor1;
    _color2 = widget.famille.gradientColor2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGradientChanged(String color1, String color2) {
    setState(() {
      _color1 = color1;
      _color2 = color2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier la famille'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nom de la famille',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            _GradientPickerDialog(
              famille: widget.famille,
              ref: widget.ref,
              initialColor1: _color1,
              initialColor2: _color2,
              onGradientChanged: _onGradientChanged,
              isDialog: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : () async {
            setState(() { _saving = true; });
            final newName = _controller.text.trim();
            bool changed = false;
            if (newName.isNotEmpty && newName != widget.famille.nom) {
              await widget.ref.read(databaseServiceProvider).updateFamilyName(widget.famille.id, newName);
              changed = true;
            }
            if (_color1 != widget.famille.gradientColor1 || _color2 != widget.famille.gradientColor2) {
              await widget.ref.read(databaseServiceProvider).updateFamilyGradient(widget.famille.id, _color1, _color2);
              changed = true;
            }
            Navigator.of(context).pop(changed);
          },
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

class _SimpleNotificationSwitch extends StatefulWidget {
  final String userId;
  final String familleId;
  const _SimpleNotificationSwitch({required this.userId, required this.familleId});

  @override
  State<_SimpleNotificationSwitch> createState() => _SimpleNotificationSwitchState();
}

class _SimpleNotificationSwitchState extends State<_SimpleNotificationSwitch> {
  bool? _active;
  bool _loading = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _fetchState();
  }

  Future<void> _fetchState() async {
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final snap = await FirebaseFirestore.instance
        .collection('familles')
        .doc(widget.familleId)
        .collection('notificationsActives')
        .doc(widget.userId)
        .get();
      setState(() {
        _active = snap.data()?['active'] ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération: $e';
        _loading = false;
      });
    }
  }

  Future<void> _setActive(bool val) async {
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await FirebaseFirestore.instance
        .collection('familles')
        .doc(widget.familleId)
        .collection('notificationsActives')
        .doc(widget.userId)
        .set({'active': val});
      setState(() {
        _active = val;
        _loading = false;
        _success = val ? 'Notifications activées.' : 'Notifications désactivées.';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la mise à jour: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Card(
        color: Colors.yellow[50],
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notifications push (expérimental)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Activez cette option pour recevoir des notifications pour cette famille (fonctionne sur mobile et PWA, expérimental sur web).'),
              const SizedBox(height: 16),
              if (_loading)
                const CircularProgressIndicator(),
              if (!_loading)
                Row(
                  children: [
                    const Text('Recevoir les notifications'),
                    const SizedBox(width: 16),
                    Switch(
                      value: _active ?? false,
                      onChanged: (val) => _setActive(val),
                    ),
                  ],
                ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_success!, style: const TextStyle(color: Colors.green)),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      print('ERREUR build _SimpleNotificationSwitch : $e\n$stack');
      return Text('ERREUR dans _SimpleNotificationSwitch : $e', style: const TextStyle(color: Colors.red));
    }
  }
}

class NotificationPreferencesWidget extends StatefulWidget {
  final String userId;
  final String familleId;
  const NotificationPreferencesWidget({required this.userId, required this.familleId});

  @override
  State<NotificationPreferencesWidget> createState() => _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState extends State<NotificationPreferencesWidget> {
  bool _loading = true;
  String? _error;
  String? _success;
  Map<String, bool> _prefs = {};
  final List<String> _eventTypes = [
    'ajout', 'suppression', 'modification', 'validation', 'invitation'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPrefs();
  }

  Future<void> _fetchPrefs() async {
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final snap = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(widget.userId)
        .collection('notifications')
        .doc(widget.familleId)
        .get();
      final data = snap.data() ?? {};
      setState(() {
        _prefs = {
          for (var e in _eventTypes) e: data[e] ?? true,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération: $e';
        _loading = false;
      });
    }
  }

  Future<void> _setPref(String event, bool val) async {
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(widget.userId)
        .collection('notifications')
        .doc(widget.familleId)
        .set({event: val}, SetOptions(merge: true));
      setState(() {
        _prefs[event] = val;
        _loading = false;
        _success = 'Préférences mises à jour.';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la mise à jour: $e';
        _loading = false;
      });
    }
  }

  Future<void> _setAll(bool val) async {
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final data = { for (var e in _eventTypes) e: val };
      await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(widget.userId)
        .collection('notifications')
        .doc(widget.familleId)
        .set(data, SetOptions(merge: true));
      setState(() {
        _prefs = Map.from(data);
        _loading = false;
        _success = val ? 'Toutes les notifications activées.' : 'Toutes les notifications désactivées.';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la mise à jour: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allActive = _prefs.values.every((v) => v);
    final allInactive = _prefs.values.every((v) => !v);
    return Card(
      color: Colors.yellow[50],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications par famille', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Activez ou désactivez les notifications pour chaque type d’événement dans cette famille.'),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator(),
            if (!_loading) ...[
              Row(
                children: [
                  const Text('Tout activer/désactiver'),
                  const SizedBox(width: 16),
                  Switch(
                    value: allActive,
                    onChanged: (val) => _setAll(val),
                  ),
                ],
              ),
              const Divider(),
              ..._eventTypes.map((event) => Row(
                children: [
                  Expanded(child: Text('Notification "$event"')),
                  Switch(
                    value: _prefs[event] ?? true,
                    onChanged: (val) => _setPref(event, val),
                  ),
                ],
              )),
            ],
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_success!, style: const TextStyle(color: Colors.green)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
} 