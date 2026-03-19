import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_provider.dart';
import '../../../../data/models/models.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/app_appbar.dart';

class AdvicePage extends StatefulWidget {
  const AdvicePage({super.key});
  @override
  State<AdvicePage> createState() => _AdvicePageState();
}

class _AdvicePageState extends State<AdvicePage> {
  String _selectedCategory = 'all';
  final List<Map<String, dynamic>> _categories = [
    {'value': 'all', 'label': 'Tous', 'icon': Icons.apps},
    {'value': 'nutrition', 'label': 'Nutrition', 'icon': Icons.restaurant_menu},
    {'value': 'activity', 'label': 'Activité', 'icon': Icons.directions_run},
    {'value': 'medication', 'label': 'Médicaments', 'icon': Icons.medication},
    {'value': 'prevention', 'label': 'Prévention', 'icon': Icons.health_and_safety},
    {'value': 'lifestyle', 'label': 'Hygiène de vie', 'icon': Icons.self_improvement},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diseaseType = provider.currentUser?.diseaseType ?? 'all';

    final allAdvice = MockData.adviceList.where((a) =>
        a.diseaseType == 'all' || a.diseaseType == diseaseType).toList();

    final filtered = _selectedCategory == 'all'
        ? allAdvice
        : allAdvice.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppAppBar(
        title: const Text('Conseils santé'),
        ispatient: provider.currentUser?.isPatient ?? false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['value'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : AppColors.background),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isSelected ? AppColors.darkBorder : (isDark ? AppColors.darkBorder : AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 14,
                          color: isSelected ? Colors.white : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(cat['label'] as String, style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const EmptyState(icon: Icons.lightbulb_outline, title: 'Aucun conseil disponible')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _buildAdviceCard(filtered[i], isDark),
            ),
    );
  }

  Widget _buildAdviceCard(AdviceModel advice, bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: advice.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lightbulb, color: advice.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(advice.title, style: AppTextStyles.h4.copyWith(color: isDark ? AppColors.darkText : AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusBadge(label: _categoryLabel(advice.category), color: advice.color),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: advice.diseaseType == 'all' ? 'Général' :
                          advice.diseaseType == 'hypertension' ? 'HTA' : 'Diabète',
                          color: advice.diseaseType == 'hypertension' ? AppColors.hypertension :
                          advice.diseaseType == 'diabetes' ? AppColors.info : AppColors.textHint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const AppDivider(),
          const SizedBox(height: 12),
          Text(advice.content, style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            height: 1.6,
          )),
        ],
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'nutrition': return 'Nutrition';
      case 'activity': return 'Activité physique';
      case 'medication': return 'Médicaments';
      case 'prevention': return 'Prévention';
      case 'lifestyle': return 'Hygiène de vie';
      default: return cat;
    }
  }
}