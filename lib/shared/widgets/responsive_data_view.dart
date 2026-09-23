import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class DataColumnSpec {
  const DataColumnSpec(this.label, {this.flex = 1});

  final String label;
  final int flex;
}

class TablePagination {
  const TablePagination({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.onPage,
  });

  final int currentPage;
  final int lastPage;
  final int total;
  final ValueChanged<int> onPage;
}

class ResponsiveDataView<T> extends StatelessWidget {
  const ResponsiveDataView({
    super.key,
    required this.items,
    required this.columns,
    required this.rowCells,
    required this.cardBuilder,
    this.onRowTap,
    this.pagination,
  });

  final List<T> items;
  final List<DataColumnSpec> columns;
  final List<Widget> Function(T item) rowCells;
  final Widget Function(T item) cardBuilder;
  final ValueChanged<T>? onRowTap;
  final TablePagination? pagination;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final table = constraints.maxWidth >= 720;
        if (!table) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items) ...[
                cardBuilder(item),
                const SizedBox(height: 10),
              ],
              if (pagination != null) ...[
                const SizedBox(height: 2),
                _PaginationShell(child: PaginationBar(pagination: pagination!)),
              ],
            ],
          );
        }

        return _PaginationShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DesktopDataTable<T>(
                items: items,
                columns: columns,
                rowCells: rowCells,
                onRowTap: onRowTap,
                viewportWidth: constraints.maxWidth,
              ),
              if (pagination != null)
                PaginationBar(pagination: pagination!, embedded: true),
            ],
          ),
        );
      },
    );
  }
}

class _PaginationShell extends StatelessWidget {
  const _PaginationShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radius - 1),
        child: child,
      ),
    );
  }
}

class _DesktopDataTable<T> extends StatefulWidget {
  const _DesktopDataTable({
    required this.items,
    required this.columns,
    required this.rowCells,
    required this.viewportWidth,
    this.onRowTap,
  });

  final List<T> items;
  final List<DataColumnSpec> columns;
  final List<Widget> Function(T item) rowCells;
  final double viewportWidth;
  final ValueChanged<T>? onRowTap;

  @override
  State<_DesktopDataTable<T>> createState() => _DesktopDataTableState<T>();
}

class _DesktopDataTableState<T> extends State<_DesktopDataTable<T>> {
  final ScrollController _scrollController = ScrollController();
  int? _hoveredRow;
  int _hoverEpoch = 0;
  bool _overflows = false;

  @override
  void initState() {
    super.initState();
    _syncOverflow();
  }

  @override
  void didUpdateWidget(covariant _DesktopDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncOverflow();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncOverflow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final overflows = _scrollController.position.maxScrollExtent > 1;
      if (overflows != _overflows) {
        setState(() => _overflows = overflows);
      }
    });
  }

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
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final wide = widget.viewportWidth >= 1440;
    final headingStyle = TextStyle(
      color: AppColors.muted,
      fontWeight: FontWeight.w700,
      letterSpacing: rtl ? 0 : 0.6,
      fontSize: 13,
      height: 1.3,
    );
    final padding = wide
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: _overflows,
      interactive: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        primary: false,
        child: _ForwardVerticalScroll(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: widget.viewportWidth),
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
                        padding: padding,
                        child: Text(
                          rtl ? column.label : column.label.toUpperCase(),
                          maxLines: 1,
                          softWrap: false,
                          style: headingStyle,
                        ),
                      ),
                  ],
                ),
                for (var index = 0; index < widget.items.length; index++)
                  _dataRow(index, padding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _dataRow(int index, EdgeInsets padding) {
    final cells = widget.rowCells(widget.items[index]);
    return TableRow(
      decoration: BoxDecoration(
        color: _hoveredRow == index ? AppColors.rowHover : AppColors.white,
      ),
      children: [
        for (var cell = 0; cell < cells.length; cell++)
          MouseRegion(
            onEnter: (_) => _enter(index),
            onExit: (_) => _leave(index),
            cursor: widget.onRowTap == null
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            child: InkWell(
              onTap: widget.onRowTap == null
                  ? null
                  : () => widget.onRowTap!(widget.items[index]),
              canRequestFocus: cell == 0 && widget.onRowTap != null,
              hoverColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: padding,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      child: cells[cell],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.pagination,
    this.embedded = false,
  });

  final TablePagination pagination;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    String number(int value) =>
        Formatters.number(value, locale: locale, decimals: 0);
    final summary = context.tr('common.pagination', {
      'total': number(pagination.total),
      'current': number(pagination.currentPage),
      'last': number(pagination.lastPage),
    });

    final previous = _PageButton(
      label: context.tr('common.previous'),
      onPressed: pagination.currentPage > 1
          ? () => pagination.onPage(pagination.currentPage - 1)
          : null,
    );
    final next = _PageButton(
      label: context.tr('common.next'),
      onPressed: pagination.currentPage < pagination.lastPage
          ? () => pagination.onPage(pagination.currentPage + 1)
          : null,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: embedded
            ? const Border(top: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summaryText = Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.4,
              ),
            );
            if (constraints.maxWidth < 640) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summaryText,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: previous),
                      const SizedBox(width: 8),
                      Expanded(child: next),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: summaryText),
                const SizedBox(width: 12),
                previous,
                const SizedBox(width: 8),
                next,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.white,
        disabledForegroundColor: AppColors.muted,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(44, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}

/// Vertical wheel and trackpad movement belong to the page. The table keeps
/// horizontal movement, including shift plus wheel.
class _ForwardVerticalScroll extends StatelessWidget {
  const _ForwardVerticalScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) {
          return;
        }
        if (event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()) {
          return;
        }
        final pressed = HardwareKeyboard.instance.logicalKeysPressed;
        if (pressed.contains(LogicalKeyboardKey.shift) ||
            pressed.contains(LogicalKeyboardKey.shiftLeft) ||
            pressed.contains(LogicalKeyboardKey.shiftRight)) {
          return;
        }
        final scrollable = _verticalScrollable(context);
        if (scrollable == null || !scrollable.position.hasContentDimensions) {
          return;
        }
        GestureBinding.instance.pointerSignalResolver.register(event, (event) {
          final scroll = event as PointerScrollEvent;
          final position = scrollable.position;
          var delta = scroll.scrollDelta.dy;
          if (scrollable.axisDirection == AxisDirection.up) {
            delta = -delta;
          }
          position.pointerScroll(delta);
          scroll.respond(allowPlatformDefault: false);
        });
      },
      child: child,
    );
  }
}

ScrollableState? _verticalScrollable(BuildContext context) {
  ScrollableState? found;
  context.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScrollableState) {
      final state = element.state as ScrollableState;
      if (state.widget.axis == Axis.vertical) {
        found = state;
        return false;
      }
    }
    return true;
  });
  return found;
}
