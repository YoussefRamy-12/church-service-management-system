part of '../spiritual_notebook_page.dart';

class _NotebookData {
  const _NotebookData(
    this.students,
    this.activities,
    this.submissions,
    this.settings,
  );
  final List<Map<String, dynamic>> students, activities, submissions;
  final Map<String, dynamic>? settings;
}
