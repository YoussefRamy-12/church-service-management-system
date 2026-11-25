part of '../spiritual_notebook_page.dart';

extension _StudentNotebookBonusSection on _SpiritualNotebookStudentPageState {
  Widget _buildBonusSection(
    BuildContext context, {
    required bool bonusAllowed,
    required bool isMobile,
    required int maxBonus,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        if (bonusAllowed) ...[
          const SizedBox(height: 14),
          SolidCard(
            borderRadius: 14,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernSectionHeader(
                  title: 'نقاط تشجيعية إضافية',
                  subtitle:
                      'يمكنك إضافة نقاط إضافية مع ذكر السبب',
                ),
                const SizedBox(height: 10),
                if (isMobile) ...[
                  TextField(
                    controller: bonus,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'النقاط (أقصى $maxBonus)',
                      prefixIcon: const Icon(
                        Icons.star_outline_rounded,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reason,
                    decoration: const InputDecoration(
                      labelText:
                          'سبب الإضافة (مطلوب إذا وضعت نقاط)',
                      prefixIcon: Icon(Icons.comment_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ] else ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: bonus,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'النقاط (أقصى $maxBonus)',
                            prefixIcon: const Icon(
                              Icons.star_outline_rounded,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: reason,
                          decoration: const InputDecoration(
                            labelText:
                                'سبب الإضافة (مطلوب إذا وضعت نقاط)',
                            prefixIcon: Icon(
                              Icons.comment_outlined,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

      ],
    );
  }
}
