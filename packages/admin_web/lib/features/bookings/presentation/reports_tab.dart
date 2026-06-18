import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/kiz_theme.dart';
import '../data/bookings_repository.dart';

/// Tab showing booking reports: summary and utilization.
class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  DateTimeRange? _dateRange;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>>? _utilization;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KizSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range picker
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _dateRange != null
                      ? '${_toIso(_dateRange!.start)} → ${_toIso(_dateRange!.end)}'
                      : 'Select Date Range',
                ),
              ),
              const SizedBox(width: KizSpacing.base),
              ElevatedButton(
                onPressed: _dateRange != null ? _loadReport : null,
                child: const Text('Load Report'),
              ),
            ],
          ),
          const SizedBox(height: KizSpacing.xl),

          if (_loading) const LinearProgressIndicator(),

          if (_error != null)
            Text(_error!,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: KizColors.error)),

          // Summary cards
          if (_summary != null) ...[
            Text('Summary', style: theme.textTheme.titleMedium),
            const SizedBox(height: KizSpacing.md),
            Wrap(
              spacing: KizSpacing.base,
              runSpacing: KizSpacing.base,
              children: _buildSummaryCards(theme),
            ),
            const SizedBox(height: KizSpacing.xl),
          ],

          // Utilization table
          if (_utilization != null && _utilization!.isNotEmpty) ...[
            Text('Utilization (${_toIso(_dateRange!.start)})',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: KizSpacing.md),
            _buildUtilizationTable(theme),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSummaryCards(ThemeData theme) {
    final entries = _summary!.entries.toList();
    return entries.map((e) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(KizSpacing.base),
          child: Column(
            children: [
              Text(
                e.value.toString(),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: KizSpacing.xs),
              Text(
                _formatKey(e.key),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildUtilizationTable(ThemeData theme) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Facility')),
        DataColumn(label: Text('Booked')),
        DataColumn(label: Text('Capacity')),
        DataColumn(label: Text('Utilization')),
      ],
      rows: _utilization!.map((row) {
        final booked = (row['booked'] as num?)?.toInt() ?? 0;
        final capacity = (row['capacity'] as num?)?.toInt() ?? 1;
        final pct = capacity > 0 ? (booked / capacity * 100).round() : 0;
        return DataRow(cells: [
          DataCell(Text(row['facilityName']?.toString() ?? '')),
          DataCell(Text('$booked')),
          DataCell(Text('$capacity')),
          DataCell(Text('$pct%')),
        ]);
      }).toList(),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  Future<void> _loadReport() async {
    if (_dateRange == null) return;
    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final from = _toIso(_dateRange!.start);
      final to = _toIso(_dateRange!.end);

      final summary = await repo.getBookingSummary(from: from, to: to);
      final utilization = await repo.getDailyUtilization(date: from);

      setState(() {
        _summary = summary;
        _utilization = utilization;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load report.';
        _loading = false;
      });
    }
  }

  String _toIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatKey(String key) {
    // Convert camelCase/snake_case to readable
    return key
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}')
        .replaceAll('_', ' ')
        .trim();
  }
}
