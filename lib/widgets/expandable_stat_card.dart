import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';

void showStatCardDetailDialog({
  required BuildContext context,
  required String title,
  required String value,
  required Color color,
  required IconData icon,
  String? hint,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 14, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: kSubText, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kSubText,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hint ?? 'Full value',
                style: TextStyle(fontSize: 11, color: kSubText.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ExpandHintIcon extends StatelessWidget {
  final Color color;

  const ExpandHintIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(Icons.open_in_full_rounded, size: 10, color: color.withOpacity(0.75)),
    );
  }
}

/// Compact summary card used on most accounting screens (row of 3).
class ExpandableStatCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final bool wrapExpanded;

  const ExpandableStatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    this.wrapExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showStatCardDetailDialog(
          context: context,
          title: title,
          value: amount,
          color: color,
          icon: icon,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        color: kSubText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ExpandHintIcon(color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (wrapExpanded) return Expanded(child: card);
    return card;
  }
}

/// Horizontal tile used on AR / Expense / Bank screens.
class ExpandableStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const ExpandableStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showStatCardDetailDialog(
          context: context,
          title: label,
          value: value,
          color: accentColor,
          icon: icon,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.18), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: kSubText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ExpandHintIcon(color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps an existing summary widget with tap-to-expand + hint icon.
class ExpandableStatWrap extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final Widget child;

  const ExpandableStatWrap({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showStatCardDetailDialog(
          context: context,
          title: title,
          value: value,
          color: color,
          icon: icon,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            child,
            Positioned(
              top: 6,
              right: 6,
              child: ExpandHintIcon(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
