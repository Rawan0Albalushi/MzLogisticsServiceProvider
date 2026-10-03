import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

const Color _ink = AppColors.ink;
const Color _muted = AppColors.muted;
const Color _border = AppColors.border;
const Color _card = AppColors.white;
const Color _accent = AppColors.teal;
const double _controlHeight = 40;
const double _gap = 8;
const double _searchMin = 220;
const double _searchMax = 480;
const double _selectWidth = 160;
const double _lookupWidth = 220;
const double _dateRangeWidth = 240;

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final specs = children.map((child) => _specOf(child, constraints.maxWidth)).toList();
          final rows = _pack(specs, constraints.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: _gap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var j = 0; j < rows[i].length; j++) ...[
                      if (j > 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: rows[i][j].width,
                        child: rows[i][j].child,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  _FilterSpec _specOf(Widget child, double maxWidth) {
    final searchMin = maxWidth < 360 ? maxWidth : (maxWidth < 600 ? 160.0 : _searchMin);
    if (child is FilterSearchField) {
      if (child.grow) {
        return _FilterSpec(child: child, grow: true, minWidth: searchMin);
      }
      final width = child.width ?? 180;
      return _FilterSpec(child: child, grow: false, minWidth: width);
    }
    if (child is FilterSelect) {
      return _FilterSpec(child: child, grow: false, minWidth: _selectWidth);
    }
    if (child is FilterLookup) {
      final width = maxWidth < _lookupWidth ? maxWidth : _lookupWidth;
      return _FilterSpec(child: child, grow: false, minWidth: width);
    }
    if (child is FilterDateRange) {
      return _FilterSpec(child: child, grow: false, minWidth: _dateRangeWidth);
    }
    return _FilterSpec(child: child, grow: false, minWidth: _selectWidth);
  }

  List<List<_PlacedFilter>> _pack(List<_FilterSpec> specs, double maxWidth) {
    final rows = <List<_FilterSpec>>[];
    var current = <_FilterSpec>[];
    var used = 0.0;

    for (final spec in specs) {
      final extra = current.isEmpty ? spec.minWidth : spec.minWidth + _gap;
      if (current.isNotEmpty && used + extra > maxWidth) {
        rows.add(current);
        current = [spec];
        used = spec.minWidth;
      } else {
        current.add(spec);
        used += extra;
      }
    }
    if (current.isNotEmpty) {
      rows.add(current);
    }

    return rows.map((row) {
      final gaps = (row.length - 1) * _gap;
      final fixed = row
          .where((item) => !item.grow)
          .fold<double>(0, (sum, item) => sum + item.minWidth);
      final growItems = row.where((item) => item.grow).toList();
      var growWidth = _searchMin;
      if (growItems.isNotEmpty) {
        final floor = growItems.map((item) => item.minWidth).reduce((a, b) => a < b ? a : b);
        final available = ((maxWidth - fixed - gaps) / growItems.length).clamp(0.0, _searchMax);
        growWidth = available < floor ? available : available.clamp(floor, _searchMax);
      }
      return [
        for (final item in row)
          _PlacedFilter(
            child: item.child,
            width: item.grow ? growWidth : item.minWidth,
          ),
      ];
    }).toList();
  }
}

class _FilterSpec {
  const _FilterSpec({
    required this.child,
    required this.grow,
    required this.minWidth,
  });

  final Widget child;
  final bool grow;
  final double minWidth;
}

class _PlacedFilter {
  const _PlacedFilter({required this.child, required this.width});

  final Widget child;
  final double width;
}

class FilterSearchField extends StatefulWidget {
  const FilterSearchField({
    super.key,
    required this.onChanged,
    this.hint,
    this.initialValue = '',
    this.width,
    this.grow = true,
  });

  final ValueChanged<String> onChanged;
  final String? hint;
  final String initialValue;
  final double? width;
  final bool grow;

  @override
  State<FilterSearchField> createState() => _FilterSearchFieldState();
}

class _FilterSearchFieldState extends State<FilterSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant FilterSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AdminControl(
      focused: _focus.hasFocus,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onChanged: _onChanged,
        cursorColor: _ink,
        style: const TextStyle(fontSize: 14, height: 1.2, color: _ink),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hintText: widget.hint ?? context.tr('common.searchPlaceholder'),
          hintStyle: const TextStyle(fontSize: 14, height: 1.2, color: _muted),
        ),
      ),
    );
  }
}

class FilterSelect extends StatelessWidget {
  const FilterSelect({
    super.key,
    required this.options,
    required this.onChanged,
    required this.labelOf,
    this.value,
    this.allLabel,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String Function(String value) labelOf;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    final resolvedAll = allLabel ?? context.tr('common.allStatuses');
    final label = empty ? resolvedAll : labelOf(value!);

    return SizedBox(
      height: _controlHeight,
      width: double.infinity,
      child: PopupMenuButton<String>(
        tooltip: resolvedAll,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        color: _card,
        elevation: 3,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: _selectWidth,
          maxWidth: 280,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border),
        ),
        onSelected: (next) => onChanged(next.isEmpty ? null : next),
        itemBuilder: (context) => [
          _menuItem('', resolvedAll),
          for (final option in options) _menuItem(option, labelOf(option)),
        ],
        child: _AdminControl(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: empty ? _muted : _ink,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20, color: _ink),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(label, style: const TextStyle(fontSize: 14, color: _ink)),
    );
  }
}

class FilterOption {
  const FilterOption({required this.value, required this.label, this.meta});

  final String value;
  final String label;
  final String? meta;
}

class FilterLookup extends StatefulWidget {
  const FilterLookup({
    super.key,
    required this.options,
    required this.onChanged,
    required this.onQuery,
    this.value,
    this.selectedLabel,
    this.allLabel,
    this.searchHint,
    this.emptyLabel,
    this.loading = false,
  });

  final List<FilterOption> options;
  final String? value;
  final String? selectedLabel;
  final ValueChanged<FilterOption?> onChanged;
  final ValueChanged<String> onQuery;
  final String? allLabel;
  final String? searchHint;
  final String? emptyLabel;
  final bool loading;

  @override
  State<FilterLookup> createState() => _FilterLookupState();
}

class _FilterLookupState extends State<FilterLookup> {
  final GlobalKey _menuKey = GlobalKey();
  OverlayEntry? _entry;

  @override
  void didUpdateWidget(covariant FilterLookup oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _close() {
    _removeOverlay();
    widget.onQuery('');
    if (mounted) {
      setState(() {});
    }
  }

  void _select(FilterOption? option) {
    widget.onChanged(option);
    _close();
  }

  void _open() {
    if (_entry != null) {
      _close();
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final overlay = Overlay.of(context, rootOverlay: true);
    final screen = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const popoverWidth = 280.0;
    final top = origin.dy + size.height + 6;
    final start = rtl ? screen.width - origin.dx - size.width : origin.dx;
    final maxStart = screen.width - popoverWidth - 8;
    final left = rtl ? null : start.clamp(8.0, maxStart < 8 ? 8.0 : maxStart);
    final right = rtl ? start.clamp(8.0, maxStart < 8 ? 8.0 : maxStart) : null;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            Positioned(
              left: left,
              right: right,
              top: top,
              width: popoverWidth,
              child: _JobLookupMenu(
                key: _menuKey,
                options: widget.options,
                value: widget.value,
                allLabel: widget.allLabel ?? context.tr('common.allJobs'),
                searchHint: widget.searchHint ?? context.tr('common.searchJob'),
                emptyLabel: widget.emptyLabel ?? context.tr('common.noResults'),
                loading: widget.loading,
                onQuery: widget.onQuery,
                onSelected: _select,
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.value == null || widget.value!.isEmpty;
    final allLabel = widget.allLabel ?? context.tr('common.allJobs');
    final label = empty ? allLabel : (widget.selectedLabel ?? '…');

    return SizedBox(
      height: _controlHeight,
      width: double.infinity,
      child: Tooltip(
        message: context.tr('common.job'),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _open,
          child: _AdminControl(
            focused: _entry != null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: empty ? _muted : _ink,
                    ),
                  ),
                ),
                if (!empty)
                  GestureDetector(
                    onTap: () => _select(null),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Tooltip(
                        message: context.tr('common.allJobs'),
                        child: const Icon(Icons.close, size: 14, color: _muted),
                      ),
                    ),
                  ),
                const Icon(Icons.arrow_drop_down, size: 20, color: _ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobLookupMenu extends StatefulWidget {
  const _JobLookupMenu({
    super.key,
    required this.options,
    required this.onQuery,
    required this.onSelected,
    required this.allLabel,
    required this.searchHint,
    required this.emptyLabel,
    required this.loading,
    this.value,
  });

  final List<FilterOption> options;
  final String? value;
  final String allLabel;
  final String searchHint;
  final String emptyLabel;
  final bool loading;
  final ValueChanged<String> onQuery;
  final ValueChanged<FilterOption?> onSelected;

  @override
  State<_JobLookupMenu> createState() => _JobLookupMenuState();
}

class _JobLookupMenuState extends State<_JobLookupMenu> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onQuery(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _card,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdminControl(
              focused: _focus.hasFocus,
              child: TextField(
                controller: _search,
                focusNode: _focus,
                onChanged: _onChanged,
                cursorColor: _ink,
                style: const TextStyle(fontSize: 14, height: 1.2, color: _ink),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: widget.searchHint,
                  hintStyle: const TextStyle(fontSize: 14, height: 1.2, color: _muted),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 248),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  _optionTile(
                    label: widget.allLabel,
                    selected: widget.value == null || widget.value!.isEmpty,
                    onTap: () => widget.onSelected(null),
                  ),
                  if (widget.options.isNotEmpty)
                    for (final option in widget.options)
                      _optionTile(
                        label: option.label,
                        meta: option.meta,
                        selected: option.value == widget.value,
                        onTap: () => widget.onSelected(option),
                      )
                  else if (widget.loading)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        context.tr('common.loading'),
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        widget.emptyLabel,
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? meta,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: _ink)),
            if (meta != null && meta.isNotEmpty)
              Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ),
      ),
    );
  }
}

class FilterDateRange extends StatefulWidget {
  const FilterDateRange({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final String? from;
  final String? to;
  final void Function(String? from, String? to) onChanged;

  @override
  State<FilterDateRange> createState() => _FilterDateRangeState();
}

class _FilterDateRangeState extends State<FilterDateRange> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _apply(String? from, String? to) {
    widget.onChanged(from, to);
  }

  void _open() {
    if (_entry != null) {
      _removeOverlay();
      setState(() {});
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final overlay = Overlay.of(context, rootOverlay: true);
    final screen = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const popoverWidth = 276.0;
    final top = origin.dy + size.height + 6;
    final start = rtl ? screen.width - origin.dx - size.width : origin.dx;
    final maxStart = screen.width - popoverWidth - 8;
    final left = rtl ? null : start.clamp(8.0, maxStart < 8 ? 8.0 : maxStart);
    final right = rtl ? start.clamp(8.0, maxStart < 8 ? 8.0 : maxStart) : null;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeOverlay();
                  setState(() {});
                },
              ),
            ),
            Positioned(
              left: left,
              right: right,
              top: top,
              width: popoverWidth,
              child: _DateRangeCalendar(
                from: widget.from,
                to: widget.to,
                onSelected: (from, to) {
                  _apply(from, to);
                  _removeOverlay();
                  setState(() {});
                },
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final empty =
        (widget.from == null || widget.from!.isEmpty) &&
        (widget.to == null || widget.to!.isEmpty);
    final label =
        !empty &&
            widget.from?.isNotEmpty == true &&
            widget.to?.isNotEmpty == true
        ? '${widget.from} – ${widget.to}'
        : widget.from?.isNotEmpty == true
        ? widget.from!
        : widget.to?.isNotEmpty == true
        ? widget.to!
        : context.tr('common.dateRange');

    return Tooltip(
      message: context.tr('common.dateRange'),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _open,
        child: _AdminControl(
          focused: _entry != null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: empty ? _muted : _ink,
                  ),
                ),
              ),
              if (!empty)
                InkWell(
                  onTap: () {
                    _removeOverlay();
                    _apply(null, null);
                    setState(() {});
                  },
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(end: 6),
                    child: Icon(Icons.close, size: 14, color: _muted),
                  ),
                ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRangeCalendar extends StatefulWidget {
  const _DateRangeCalendar({
    required this.from,
    required this.to,
    required this.onSelected,
  });

  final String? from;
  final String? to;
  final void Function(String from, String to) onSelected;

  @override
  State<_DateRangeCalendar> createState() => _DateRangeCalendarState();
}

class _DateRangeCalendarState extends State<_DateRangeCalendar> {
  late DateTime _cursor;
  late String _draftFrom;
  late String _draftTo;
  var _step = _DateStep.start;
  String _hover = '';

  @override
  void initState() {
    super.initState();
    _draftFrom = widget.from ?? '';
    _draftTo = widget.to ?? '';
    final parsed =
        DateTime.tryParse(_draftFrom) ??
        DateTime.tryParse(_draftTo) ??
        DateTime.now();
    _cursor = DateTime(parsed.year, parsed.month, 1);
  }

  String _iso(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _parse(String value) => DateTime.tryParse(value);

  void _select(DateTime date) {
    final iso = _iso(date);
    if (_step == _DateStep.start || _draftFrom.isEmpty) {
      setState(() {
        _draftFrom = iso;
        _draftTo = '';
        _hover = '';
        _step = _DateStep.end;
      });
      return;
    }
    final start = _parse(_draftFrom);
    if (start == null) {
      setState(() {
        _draftFrom = iso;
        _step = _DateStep.end;
      });
      return;
    }
    final clicked = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final nextFrom = clicked.isBefore(startDay) ? iso : _draftFrom;
    final nextTo = clicked.isBefore(startDay) ? _draftFrom : iso;
    widget.onSelected(nextFrom, nextTo);
  }

  List<DateTime?> _days() {
    final first = DateTime(_cursor.year, _cursor.month, 1);
    final startOffset = first.weekday % 7;
    final total = DateTime(_cursor.year, _cursor.month + 1, 0).day;
    return [
      for (var i = 0; i < startOffset + total; i++)
        i < startOffset
            ? null
            : DateTime(_cursor.year, _cursor.month, i - startOffset + 1),
    ];
  }

  bool _inRange(DateTime date, DateTime start, DateTime end) {
    final day = DateTime(date.year, date.month, date.day);
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    final rangeStart = from.isBefore(to) || from.isAtSameMomentAs(to)
        ? from
        : to;
    final rangeEnd = from.isBefore(to) || from.isAtSameMomentAs(to) ? to : from;
    return !day.isBefore(rangeStart) && !day.isAfter(rangeEnd);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final weekdays = l10n.narrowWeekdays;
    final previewEnd = _draftTo.isNotEmpty
        ? _draftTo
        : (_step == _DateStep.end ? _hover : '');
    final start = _parse(_draftFrom);
    final end = _parse(previewEnd);
    final today = _iso(DateTime.now());

    return Material(
      color: _card,
      elevation: 4,
      shadowColor: const Color(0x1A12202B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  onTap: () => setState(
                    () =>
                        _cursor = DateTime(_cursor.year, _cursor.month - 1, 1),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.formatMonthYear(_cursor),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: () => setState(
                    () =>
                        _cursor = DateTime(_cursor.year, _cursor.month + 1, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final day in weekdays)
                  Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.tr(
                  _step == _DateStep.end
                      ? 'common.dateRangePickEnd'
                      : 'common.dateRangePickStart',
                ),
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.15,
              children: [
                for (final date in _days())
                  if (date == null)
                    const SizedBox.shrink()
                  else
                    MouseRegion(
                      onEnter: (_) => setState(() => _hover = _iso(date)),
                      onExit: (_) => setState(() => _hover = ''),
                      child: _DayCell(
                        day: date.day,
                        selected:
                            _iso(date) == _draftFrom ||
                            _iso(date) == previewEnd,
                        inRange:
                            start != null &&
                            end != null &&
                            _inRange(date, start, end),
                        today: _iso(date) == today,
                        onTap: () => _select(date),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _DateStep { start, end }

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(icon, size: 18, color: _ink),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.inRange,
    required this.today,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool inRange;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _accent
          : inRange
          ? AppColors.tealSoft
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: today && !selected ? Border.all(color: _accent) : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : _ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminControl extends StatelessWidget {
  const _AdminControl({required this.child, this.focused = false});

  final Widget child;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: focused ? _accent : _border),
        boxShadow: focused
            ? const [
                BoxShadow(
                  color: AppColors.focusRing,
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }
}
