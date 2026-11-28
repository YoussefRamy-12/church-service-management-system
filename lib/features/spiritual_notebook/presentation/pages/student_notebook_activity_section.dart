// ignore_for_file: invalid_use_of_protected_member

part of '../spiritual_notebook_page.dart';

extension _StudentNotebookActivitySection on _SpiritualNotebookStudentPageState {
  Widget _buildActivityTiles(
    BuildContext context,
    List<Map<String, dynamic>> activities,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: [
        for (final a in activities) ...[
          Builder(
            builder: (context) {
              final isChecked = selected.contains(a['id']);
              return SolidCard(
                margin: const EdgeInsets.only(bottom: 8),
                borderRadius: 12,
                padding: EdgeInsets.zero,
                color: isChecked
                    ? Theme.of(context).colorScheme.primary.withValues(
                        alpha: isDark ? 0.12 : 0.05,
                      )
                    : null,
                border: isChecked
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        selected.remove(a['id'] as String);
                      } else {
                        selected.add(a['id'] as String);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selected.add(a['id'] as String);
                              } else {
                                selected.remove(
                                  a['id'] as String,
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['name'] as String,
                                style: TextStyle(
                                  fontWeight: isChecked
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (a['description'] != null &&
                                  (a['description'] as String)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  a['description'].toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  ),
                            borderRadius: BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: Text(
                            '+${a['points']} ن',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isChecked
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],


      ],
    );
  }
}
