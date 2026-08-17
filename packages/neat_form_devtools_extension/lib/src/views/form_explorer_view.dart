import 'package:flutter/material.dart';
import 'package:neat_form_devtools_extension/src/controllers/devtools_service_controller.dart';
import 'package:neat_form_devtools_extension/src/models/form_summary.dart';

/// Left panel displaying searchable list of active standard forms and dynamic form arrays.
class FormExplorerView extends StatefulWidget {
  const FormExplorerView({super.key, required this.controller});

  final DevToolsServiceController controller;

  @override
  State<FormExplorerView> createState() => _FormExplorerViewState();
}

class _FormExplorerViewState extends State<FormExplorerView> {
  final TextEditingController searchController = TextEditingController();
  String filterQuery = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => filterQuery = searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search & Filter Box
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter forms (name/ID)...',
              prefixIcon: const Icon(Icons.search, size: 16),
              suffixIcon: filterQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const Divider(height: 1),

        // Forms List View
        Expanded(
          child: ValueListenableBuilder<List<FormSummary>>(
            valueListenable: widget.controller.formsNotifier,
            builder: (context, allForms, _) {
              final forms = allForms.where((f) {
                if (filterQuery.isEmpty) return true;
                return f.name.toLowerCase().contains(filterQuery) ||
                    f.id.toLowerCase().contains(filterQuery);
              }).toList();

              if (forms.isEmpty) {
                return Center(
                  child: Text(
                    filterQuery.isEmpty ? 'No active forms' : 'No matching forms',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }

              final standardForms = forms.where((f) => !f.isArray).toList();
              final arrayForms = forms.where((f) => f.isArray).toList();

              return ListView(
                children: [
                  if (standardForms.isNotEmpty) ...[
                    _buildSectionHeader('STANDARD FORMS', standardForms.length, theme),
                    ...standardForms.map((f) => _buildFormTile(f, theme)),
                  ],
                  if (arrayForms.isNotEmpty) ...[
                    _buildSectionHeader('DYNAMIC FORM ARRAYS', arrayForms.length, theme),
                    ...arrayForms.map((f) => _buildFormTile(f, theme)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTile(FormSummary item, ThemeData theme) {
    final isSelected = item.id == widget.controller.selectedFormId;

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: Icon(
        item.isArray ? Icons.list_alt : Icons.assignment_outlined,
        color: item.isValid ? Colors.green : Colors.redAccent,
        size: 18,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            item.isArray ? '${item.itemsCount} items' : '${item.fieldsCount} fields',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 6),
          Text(
            '• ${item.status}',
            style: TextStyle(
              fontSize: 10.5,
              color: item.status == 'submitting' ? Colors.blue : null,
              fontWeight: item.status == 'submitting' ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
      onTap: () => widget.controller.selectForm(item.id),
    );
  }
}
