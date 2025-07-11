import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_liste/pages/creer_famille_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// On importe mobile_scanner uniquement si ce n'est pas le web
// ignore: uri_does_not_exist
import 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.html) 'package:my_liste/pages/qr_scanner_stub.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class JoinOrCreateFamilyPage extends ConsumerWidget {
  const JoinOrCreateFamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une famille'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
              context.go('/accueil');
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dernière étape !',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Pour continuer, rejoignez une famille existante avec un code ou créez la vôtre.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Rejoindre une famille
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _JoinFamilyDialog(ref: ref),
                  );
                },
                icon: const Icon(Icons.group_add),
                label: const Text('Rejoindre une famille'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OU'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Créer une famille
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreerFamillePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer une nouvelle famille'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinFamilyDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _JoinFamilyDialog({required this.ref});

  @override
  ConsumerState<_JoinFamilyDialog> createState() => _JoinFamilyDialogState();
}

class _JoinFamilyDialogState extends ConsumerState<_JoinFamilyDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS ||
        (MediaQuery.of(context).size.width < 600);

    return AlertDialog(
      title: const Text('Rejoindre une famille'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Code d\'invitation',
              prefixIcon: Icon(Icons.vpn_key),
            ),
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          if (isMobile && !kIsWeb)
            ElevatedButton.icon(
              onPressed: _scanQrCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scanner un QR code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          if (!isMobile || kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Le scan de QR code n\'est disponible que sur mobile.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _joinFamily,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Valider'),
        ),
      ],
    );
  }

  Future<void> _joinFamily() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _error = 'Veuillez entrer un code.';
        _loading = false;
      });
      return;
    }
    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      await widget.ref.read(databaseServiceProvider).joinFamilyWithCode(code, user);
      if (mounted) {
        context.go('/accueil');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez rejoint la famille !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _scanQrCode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const _QrScanPage()),
    );
    if (code != null && code.isNotEmpty) {
      setState(() {
        _codeController.text = code;
      });
    }
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un QR code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && code.isNotEmpty) {
              setState(() => _scanned = true);
              Navigator.of(context).pop(code);
              break;
            }
          }
        },
      ),
    );
  }
} 