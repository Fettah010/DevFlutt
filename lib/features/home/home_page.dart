import 'package:flutter/material.dart';

/// The blank app's single example screen.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('DevFlutt')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flutter_dash,
                size: 72,
                color: theme.colorScheme.primary,
                semanticLabel: 'Flutter logo',
              ),
              const SizedBox(height: 16),
              Text(
                'Blank-first Flutter starter',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This blank app makes no network requests and requests no '
                'permissions. Start building here.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
