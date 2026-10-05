import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/l10n/l10n.dart';

/// Shown for an unknown address, e.g. /locations/does-not-exist on the web.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.notFoundMessage),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/explore'),
              child: Text(l10n.notFoundBack),
            ),
          ],
        ),
      ),
    );
  }
}
