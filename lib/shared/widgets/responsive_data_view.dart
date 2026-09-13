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

    return _DesktopDataTable<T>(
      items: items,
      columns: columns,
      rowCells: rowCells,
      onRowTap: onRowTap,
    );
  }
}

class _DesktopDataTable<T> extends StatefulWidget {
  const _DesktopDataTable({
    required this.items,
    required this.columns,
    required this.rowCells,
    this.onRowTap,
  });

  final List<T> items;
  final List<DataColumnSpec> columns;
  final List<Widget> Function(T item) rowCells;
  final ValueChanged<T>? onRowTap;

  @override
  State<_DesktopDataTable<T>> createState() => _DesktopDataTableState<T>();
}

class _DesktopDataTableState<T> extends State<_DesktopDataTable<T>> {
  int? _hoveredRow;
  int _hoverEpoch = 0;

  void _enter(int index) {
    _hoverEpoch++;
    if (_hoveredRow != index) {
      setState(() => _hoveredRow = index);
    }
  }

  void _leave(int index) {
    final epoch = ++_hoverEpoch;
    Future<void>.microtask(() {
      if (!mounted || epoch != _hoverEpoch || _hoveredRow != index) {
        return;
      }
      setState(() => _hoveredRow = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.dataTableTheme.headingTextStyle ??
        theme.textTheme.labelMedium?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          fontSize: 11,
        );
    final canTap = widget.onRowTap != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: const TableBorder(
                  horizontalInside: BorderSide(color: AppColors.border),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.surface),
                    children: [
                      for (final column in widget.columns)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(column.label, style: headingStyle),
                        ),
                    ],
                  ),
                  for (var index = 0; index < widget.items.length; index++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: _hoveredRow == index ? AppColors.rowHover : AppColors.white,
                      ),
                      children: [
                        for (final cell in widget.rowCells(widget.items[index]))
                          MouseRegion(
                            onEnter: (_) => _enter(index),
                            onExit: (_) => _leave(index),
                            cursor: canTap ? SystemMouseCursors.click : MouseCursor.defer,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: canTap ? () => widget.onRowTap!(widget.items[index]) : null,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 54),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: cell,
                                  ),
                                ),
                              ),
                            ),
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
