import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:neat_form_devtools_extension/src/controllers/devtools_service_controller.dart';
import 'package:neat_form_devtools_extension/src/models/form_summary.dart';
import 'package:neat_form_devtools_extension/src/views/actions_timeline_view.dart';
import 'package:neat_form_devtools_extension/src/views/field_inspector_view.dart';
import 'package:neat_form_devtools_extension/src/views/form_explorer_view.dart';

/// Root UI Widget for NeatForm Flutter DevTools Extension.
class NeatFormDevToolsApp extends StatefulWidget {
  const NeatFormDevToolsApp({super.key, this.controller});

  final DevToolsServiceController? controller;

  @override
  State<NeatFormDevToolsApp> createState() => _NeatFormDevToolsAppState();
}

class _NeatFormDevToolsAppState extends State<NeatFormDevToolsApp> {
  late final DevToolsServiceController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? DevToolsServiceController();
    controller.init();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.dynamic_form_outlined, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'NeatForm DevTools',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<List<FormSummary>>(
                  valueListenable: controller.formsNotifier,
                  builder: (context, forms, _) {
                    return Text(
                      '${forms.length} active instances',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    );
                  },
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: controller.isLoadingNotifier,
                  builder: (context, isLoading, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        DevToolsButton(
                          icon: Icons.refresh,
                          tooltip: 'Refresh Active Forms',
                          onPressed: isLoading ? null : () => controller.fetchForms(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Error Banner if present
          ValueListenableBuilder<String?>(
            valueListenable: controller.errorNotifier,
            builder: (context, error, _) {
              if (error == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.redAccent.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(error, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),

          // Body: 3-Panel Split View
          Expanded(
            child: ValueListenableBuilder<List<FormSummary>>(
              valueListenable: controller.formsNotifier,
              builder: (context, forms, _) {
                if (forms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No active NeatForm instances detected',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Initialize a NeatFormController or NeatFormArrayController in your running application to inspect it here.',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        DevToolsButton(
                          icon: Icons.refresh,
                          label: 'Check Again',
                          onPressed: () => controller.fetchForms(),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    // Left Panel (Width: 260): Form Explorer
                    SizedBox(
                      width: 260,
                      child: FormExplorerView(controller: controller),
                    ),
                    const VerticalDivider(width: 1),

                    // Center Panel (Flexible: 3): Field Inspector & Live Editor
                    Expanded(
                      flex: 3,
                      child: FieldInspectorView(controller: controller),
                    ),
                    const VerticalDivider(width: 1),

                    // Right Panel (Flexible: 2, minWidth: 280): Actions & Live Timeline
                    Expanded(
                      flex: 2,
                      child: ActionsTimelineView(controller: controller),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
