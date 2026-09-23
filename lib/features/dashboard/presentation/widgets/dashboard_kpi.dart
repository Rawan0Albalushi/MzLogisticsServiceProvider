import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/page_visuals.dart';
import '../../../../shared/widgets/icon_well.dart';

enum DashboardKpiTone { neutral, info, warning, success, danger }

class DashboardKpi {
  const DashboardKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hint,
    this.tone = DashboardKpiTone.neutral,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final VoidCallback onTap;
  final DashboardKpiTone tone;
}

class DashboardAttentionItem {
  const DashboardAttentionItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.tone,
    required this.viewLabel,
    required this.onTap,
  });

  final String label;
  final String count;
  final IconData icon;
  final DashboardKpiTone tone;
  final String viewLabel;
  final VoidCallback onTap;
}

class DashboardQuickLink {
  const DashboardQuickLink({
    required this.title,
    required this.hint,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final String hint;
  final IconData icon;
  final IconTone tone;
  final VoidCallback onTap;
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DecoratedBox(
      decoration: dashboardPanelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              rtl ? title : title.toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: rtl ? 0 : 0.9,
                color: AppColors.muted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({super.key, required this.metrics});

  final List<DashboardKpi> metrics;

  @override
  Widget build(BuildContext context) {
    return _AdaptiveGrid(
      minItemWidth: 240,
      itemCount: metrics.length,
      itemBuilder: (index) => _KpiTile(metric: metrics[index]),
    );
  }
}

class DashboardAttentionList extends StatelessWidget {
  const DashboardAttentionList({super.key, required this.items});

  final List<DashboardAttentionItem> items;

  @override
  Widget build(BuildContext context) {
    return _AdaptiveGrid(
      minItemWidth: 220,
      itemCount: items.length,
      itemBuilder: (index) => _AttentionTile(item: items[index]),
    );
  }
}

class DashboardQuickLinkGrid extends StatelessWidget {
  const DashboardQuickLinkGrid({super.key, required this.links});

  final List<DashboardQuickLink> links;

  @override
  Widget build(BuildContext context) {
    return _AdaptiveGrid(
      minItemWidth: 220,
      itemCount: links.length,
      itemBuilder: (index) => _QuickLinkTile(link: links[index]),
    );
  }
}

class _AdaptiveGrid extends StatelessWidget {
  const _AdaptiveGrid({
    required this.minItemWidth,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double minItemWidth;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columns(constraints.maxWidth, itemCount, minItemWidth);
        final rows = <Widget>[];
        for (var index = 0; index < itemCount; index += columns) {
          final end = math.min(index + columns, itemCount);
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: 12));
          }
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var cell = index; cell < end; cell++) ...[
                  if (cell > index) const SizedBox(width: 12),
                  Expanded(child: itemBuilder(cell)),
                ],
                if (end - index < columns)
                  Spacer(flex: columns - (end - index)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  int _columns(double width, int count, double minWidth) {
    final fitted = math.max(1, (width / minWidth).floor());
    return math.min(fitted, count);
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.metric});

  final DashboardKpi metric;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(metric.tone);
    return _DashboardCard(
      onTap: metric.onTap,
      radius: 10,
      decoration: BoxDecoration(
        color: colors.background,
        gradient: colors.wash,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 148),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _KpiIcon(icon: metric.icon, colors: colors),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metric.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                metric.hint ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiIcon extends StatelessWidget {
  const _KpiIcon({required this.icon, required this.colors});

  final IconData icon;
  final _ToneColors colors;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.iconBackground,
          borderRadius: BorderRadius.circular(10),
          border: colors.iconBorder,
        ),
        child: Icon(icon, size: 15, color: colors.icon),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item});

  final DashboardAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(item.tone);
    return _DashboardCard(
      onTap: item.onTap,
      radius: 10,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconWell(
                icon: item.icon,
                tone: colors.iconTone,
                size: IconWellSize.md,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.viewLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.count,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.icon,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({required this.link});

  final DashboardQuickLink link;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      onTap: link.onTap,
      radius: 12,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconWell(icon: link.icon, tone: link.tone, size: IconWellSize.lg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      link.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  const _DashboardCard({
    required this.onTap,
    required this.radius,
    required this.decoration,
    required this.child,
  });

  final VoidCallback onTap;
  final double radius;
  final BoxDecoration decoration;
  final Widget child;

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final lifted = _hovered && !reduceMotion;
    final radius = BorderRadius.circular(widget.radius);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: reduceMotion ? 0 : 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
        transformAlignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            hoverColor: Colors.transparent,
            splashColor: AppColors.rowHover,
            child: Ink(
              decoration: widget.decoration.copyWith(
                borderRadius: radius,
                border: Border.all(
                  color: _hovered ? AppColors.hoverBorder : AppColors.border,
                ),
                boxShadow: lifted ? dashboardCardHoverShadow : const [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToneColors {
  const _ToneColors({
    required this.background,
    required this.icon,
    required this.iconBackground,
    required this.pill,
    required this.iconTone,
    this.wash,
    this.iconBorder,
  });

  final Color background;
  final Color icon;
  final Color iconBackground;
  final Color pill;
  final IconTone iconTone;
  final Gradient? wash;
  final Border? iconBorder;
}

_ToneColors _toneColors(DashboardKpiTone tone) {
  return switch (tone) {
    DashboardKpiTone.neutral => const _ToneColors(
      background: AppColors.surface,
      icon: AppColors.teal800,
      iconBackground: AppColors.white,
      pill: AppColors.chipBg,
      iconTone: IconTone.teal,
      iconBorder: Border.fromBorderSide(BorderSide(color: AppColors.border)),
    ),
    DashboardKpiTone.info => const _ToneColors(
      background: AppColors.white,
      icon: AppColors.info,
      iconBackground: AppColors.infoSoft,
      pill: AppColors.infoSoft,
      iconTone: IconTone.info,
      wash: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.infoSoft, AppColors.white],
        stops: [0, 0.42],
      ),
    ),
    DashboardKpiTone.warning => const _ToneColors(
      background: AppColors.white,
      icon: AppColors.warning,
      iconBackground: AppColors.warningSoft,
      pill: AppColors.warningSoft,
      iconTone: IconTone.warning,
      wash: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.warningSoft, AppColors.white],
        stops: [0, 0.42],
      ),
    ),
    DashboardKpiTone.success => const _ToneColors(
      background: AppColors.white,
      icon: AppColors.success,
      iconBackground: AppColors.successSoft,
      pill: AppColors.successSoft,
      iconTone: IconTone.success,
      wash: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.successSoft, AppColors.white],
        stops: [0, 0.42],
      ),
    ),
    DashboardKpiTone.danger => const _ToneColors(
      background: AppColors.white,
      icon: AppColors.danger,
      iconBackground: AppColors.dangerSoft,
      pill: AppColors.dangerSoft,
      iconTone: IconTone.danger,
      wash: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.dangerSoft, AppColors.white],
        stops: [0, 0.42],
      ),
    ),
  };
}

const dashboardCardShadow = [
  BoxShadow(color: Color(0x0F142426), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0F142426), blurRadius: 24, offset: Offset(0, 8)),
];

const dashboardCardHoverShadow = [
  BoxShadow(color: Color(0x1A142426), blurRadius: 22, offset: Offset(0, 10)),
];

const dashboardPanelDecoration = BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.all(Radius.circular(14)),
  border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
  boxShadow: dashboardCardShadow,
);

const dashboardSurfaceDecoration = BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.all(Radius.circular(AppColors.radius)),
  border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
  boxShadow: dashboardCardShadow,
);
