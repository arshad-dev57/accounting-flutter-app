import 'dart:ui';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardBreadcrumbSegment {
  final String label;
  final VoidCallback? onTap;

  const DashboardBreadcrumbSegment({
    required this.label,
    this.onTap,
  });
}

/// Top breadcrumb for mobile dashboards — tap earlier segments to go back.
class DashboardBreadcrumbBar extends StatelessWidget {
  final List<DashboardBreadcrumbSegment> segments;

  const DashboardBreadcrumbBar({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FC),
        border: Border(bottom: BorderSide(color: Color(0xFFEEEFF4))),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
            _Crumb(segment: segments[i], isLast: i == segments.length - 1),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  final DashboardBreadcrumbSegment segment;
  final bool isLast;

  const _Crumb({required this.segment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final canTap = segment.onTap != null && !isLast;
    final style = TextStyle(
      fontSize: 13,
      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
      color: isLast ? kPrimary : (canTap ? const Color(0xFF5B6478) : Colors.grey.shade500),
    );

    if (!canTap) {
      return Text(segment.label, style: style);
    }

    return InkWell(
      onTap: segment.onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(segment.label, style: style),
      ),
    );
  }
}

class DashboardBottomNavItem {
  final String label;
  /// SVG under assets/icons/ — add file if missing (e.g. income.svg).
  final String iconAsset;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final bool selected;

  const DashboardBottomNavItem({
    required this.label,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.onTap,
    this.selected = false,
  });
}

/// Floating rounded glass bottom bar for mobile dashboards.
class DashboardGlassBottomNav extends StatelessWidget {
  final List<DashboardBottomNavItem> items;

  const DashboardGlassBottomNav({super.key, required this.items});

  static double reservedHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 64;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
              ),
              child: Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: _BottomNavTile(item: item),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavTile extends StatelessWidget {
  final DashboardBottomNavItem item;

  const _BottomNavTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.selected ? kPrimary : const Color(0xFF8A8FA8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: item.selected
                      ? kPrimary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _NavSvgIcon(
                  asset: item.iconAsset,
                  fallback: item.fallbackIcon,
                  color: color,
                  size: 17,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: item.selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSvgIcon extends StatelessWidget {
  final String asset;
  final IconData fallback;
  final Color color;
  final double size;

  const _NavSvgIcon({
    required this.asset,
    required this.fallback,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Avoid async SVG load crashes — show fallback if asset missing.
    return FutureBuilder<ByteData>(
      future: DefaultAssetBundle.of(context).load(asset),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SvgPicture.asset(
            asset,
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          );
        }
        return Icon(fallback, size: size, color: color);
      },
    );
  }
}
