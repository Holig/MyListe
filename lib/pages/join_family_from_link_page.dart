import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_liste/services/database_service.dart';
import 'package:my_liste/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinFamilyFromLinkPage extends ConsumerStatefulWidget {
  final String code;
  const JoinFamilyFromLinkPage({super.key, required this.code});

  @override
  ConsumerState<JoinFamilyFromLinkPage> createState() => _JoinFamilyFromLinkPageState();
}

class _JoinFamilyFromLinkPageState extends ConsumerState<JoinFamilyFromLinkPage> {
  late TextEditingController _codeController;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.code);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS ||
        (MediaQuery.of(context).size.width < 600);

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
                'Invitation à rejoindre une famille',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Saisissez ou scannez le code d\'invitation pour rejoindre la famille.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
              if (isMobile)
                ElevatedButton.icon(
                  onPressed: _scanQrCode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner un QR code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _joinFamily,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Valider'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/accueil'),
                      child: const Text('Annuler'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      await ref.read(databaseServiceProvider).joinFamilyWithCode(code, user);
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