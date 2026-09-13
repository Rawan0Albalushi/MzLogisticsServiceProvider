import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';

class DataColumnSpec {
  const DataColumnSpec(this.label, {this.flex = 1});

  final String label;
  final int flex;
}

class ResponsiveDataView<T> extends StatelessWidget {
  const ResponsiveDataView({
    super.key,
    required this.items,
    required this.columns,
    required this.rowCells,
    required this.cardBuilder,
    this.onRowTap,
  });

  final List<T> items;
  final List<DataColumnSpec> columns;
  final List<Widget> Function(T item) rowCells;
  final Widget Function(T item) cardBuilder;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (!Breakpoints.isDesktop(context)) {
      return Column(
        children: [
          for (final item in items) ...[
            cardBuilder(item),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowHeight: 44,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 68,
                columns: [
                  for (final column in columns) DataColumn(label: Text(column.label)),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        for (final cell in rowCells(item))
                          DataCell(
                            cell,
                            onTap: onRowTap == null ? null : () => onRowTap!(item),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onPage,
  });

  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(
            context.tr('common.pageOf', {
              'current': '$currentPage',
              'last': '$lastPage',
            }),
            style: const TextStyle(color: AppColors.muted),
          ),
          const Spacer(),
          IconButton(
            onPressed: currentPage > 1 ? () => onPage(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: currentPage < lastPage ? () => onPage(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

