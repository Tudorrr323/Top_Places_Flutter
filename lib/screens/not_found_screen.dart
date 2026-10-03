import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown for an unknown address, e.g. /locations/does-not-exist on the web.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagină inexistentă')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nu am găsit pagina căutată.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Înapoi la Explorează'),
            ),
          ],
        ),
      ),
    );
  }
}