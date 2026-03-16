import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_utils.dart';

// ─── Section Header ───
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h4),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w600,
            )),
          ),
      ],
    );
  }
}

// ─── App Card ───
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? (isDark ? AppColors.darkSurface : AppColors.white),
          borderRadius: BorderRadius.circular(16),
          border: border ?? Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Status Badge ───
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;

  const StatusBadge({super.key, required this.label, required this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(
        color: color, fontWeight: FontWeight.w700,
      )),
    );
  }
}

// ─── Measurement Value Widget ───
class MeasurementChip extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;

  const MeasurementChip({super.key, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: color, fontSize: 24)),
        const SizedBox(width: 2),
        Text(unit, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
      ],
    );
  }
}

// ─── Empty State ───
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─── Metric Card ───
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const MetricCard({
    super.key, required this.label, required this.value, required this.unit,
    required this.status, required this.statusColor, required this.icon,
    required this.iconColor, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: AppTextStyles.caption.copyWith(
                    color: statusColor, fontWeight: FontWeight.w700,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, letterSpacing: 0.5,
            )),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.textPrimary, fontSize: 22,
                )),
                const SizedBox(width: 3),
                Text(unit, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Primary Button ───
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const PrimaryButton({
    super.key, required this.label, this.onPressed, this.isLoading = false, this.icon, this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: AppTextStyles.button.copyWith(color: Colors.white)),
                ],
              ),
      ),
    );
  }
}

// ─── Disease Tag ───
class DiseaseTag extends StatelessWidget {
  final String diseaseType;
  const DiseaseTag({super.key, required this.diseaseType});

  @override
  Widget build(BuildContext context) {
    final isHypertension = diseaseType == 'hypertension';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHypertension ? AppColors.hypertensionLight : AppColors.diabetesLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isHypertension ? AppColors.hypertension : AppColors.diabetes).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHypertension ? Icons.favorite : Icons.water_drop,
            size: 12,
            color: isHypertension ? AppColors.hypertension : AppColors.diabetes,
          ),
          const SizedBox(width: 4),
          Text(
            isHypertension ? 'Hypertension' : 'Diabète',
            style: AppTextStyles.caption.copyWith(
              color: isHypertension ? AppColors.hypertension : AppColors.diabetes,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Divider ───
class AppDivider extends StatelessWidget {
  final double? indent;
  const AppDivider({super.key, this.indent});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.divider,
      height: 1, indent: indent, endIndent: 0,
    );
  }
}

// ─── Info Row ───
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label : ', style: AppTextStyles.bodySmall),
        Expanded(
          child: Text(value, style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.textPrimary,
          )),
        ),
      ],
    );
  }
}