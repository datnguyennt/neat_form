import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:neat_form_devtools_extension/src/neat_form_devtools_app.dart';

void main() {
  runApp(const NeatFormDevToolsExtension());
}

/// Main DevTools Extension wrapper widget.
class NeatFormDevToolsExtension extends StatelessWidget {
  const NeatFormDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: NeatFormDevToolsApp(),
    );
  }
}
