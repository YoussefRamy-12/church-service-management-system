part of '../spiritual_notebook_page.dart';

extension _StudentNotebookFooterSection on _SpiritualNotebookStudentPageState {
  Widget? _buildStickySubmitBar(
    BuildContext context, {
    required Map<String, dynamic>? existing,
    required int grandTotal,
    required ThemeData theme,
  }) {
    if (existing != null || MediaQuery.sizeOf(context).width >= 600) {
      return null;
    }
    final hasNext = widget.studentIds.isNotEmpty &&
        widget.studentIndex < widget.studentIds.length - 1;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مجموع نقاط الأسبوع',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$grandTotal نقطة',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: saving
                  ? null
                  : () => _submitRecord(goToNext: hasNext),
              icon: const Icon(Icons.save_rounded),
              label: Text(
                saving ? 'جارٍ الحفظ...' : (hasNext ? 'حفظ والتالي' : 'حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<Widget> _buildStudentNavigationActions(
    BuildContext context,
    ThemeData theme,
  ) {
    if (widget.studentIds.isEmpty) return const [];

    return [
      IconButton(
        tooltip: 'التلميذ السابق',
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        onPressed: widget.studentIndex > 0
            ? () => _openStudentAt(widget.studentIndex - 1)
            : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
      Center(
        child: Text(
          '${widget.studentIndex + 1}/${widget.studentIds.length}',
          style: theme.textTheme.labelSmall,
        ),
      ),
      IconButton(
        tooltip: 'التلميذ التالي',
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        onPressed: widget.studentIndex < widget.studentIds.length - 1
            ? () => _openStudentAt(widget.studentIndex + 1)
            : null,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
    ];
  }

}
