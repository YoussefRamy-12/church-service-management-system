part of '../spiritual_notebook_page.dart';

extension _StudentListFilterBuilders on _StudentListState {
  Widget _filterChip({required String label, required int count, required bool selected, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label، $count',
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
        child: ChoiceChip(
          label: Text('$label ($count)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          selectedColor: scheme.secondaryContainer,
          side: BorderSide(color: selected ? scheme.secondary : scheme.outlineVariant),
          visualDensity: VisualDensity.standard,
        ),
      ),
    );
  }

  void _showClassFilterSheet(BuildContext context, List<MapEntry<String, String>> classes, Map<String, int> counts) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('اختيار الفصل', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(child: ListView(children: [
              RadioListTile<String?>(value: null, groupValue: selectedClassId, title: const Text('كل الفصول'), secondary: Text(widget.students.length.toString()),
                onChanged: (_) { setState(() => selectedClassId = null); Navigator.pop(sheetContext); }),
              for (final entry in classes)
                RadioListTile<String?>(value: entry.key, groupValue: selectedClassId, title: Text(entry.value), secondary: Text('${counts[entry.key] ?? 0}'),
                  onChanged: (_) { setState(() => selectedClassId = entry.key); Navigator.pop(sheetContext); }),
            ])),
          ]),
        ),
      ),
    );
  }
}
