import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../data/models/models.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../shared/widgets/app_appbar.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class SelfAssessmentPage extends StatefulWidget {
  const SelfAssessmentPage({super.key});
  @override
  State<SelfAssessmentPage> createState() => _SelfAssessmentPageState();
}

class _SelfAssessmentPageState extends State<SelfAssessmentPage> {
  final _questions = MockData.assessmentQuestions;
  int _currentIndex = 0;
  final Map<String, SelfAssessmentOption> _answers = {};
  bool _isCompleted = false;
  SelfAssessmentResult? _result;

  void _selectOption(SelfAssessmentOption option) {
    final question = _questions[_currentIndex];
    setState(() => _answers[question.id] = option);
  }

  void _next() {
    if (_answers[_questions[_currentIndex].id] == null) return;
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _computeResult();
    }
  }

  void _prev() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _computeResult() {
    final provider = context.read<AppProvider>();
    final user = provider.currentUser!;
    final age = AppUtils.calculateAge(user.dateOfBirth);

    int totalScore = _answers.values.fold(0, (sum, opt) => sum + opt.riskScore);

    // Age bonus
    if (age >= 45 && age < 60) totalScore += 1;
    if (age >= 60) totalScore += 2;

    final catScores = <String, int>{};
    for (final q in _questions) {
      final ans = _answers[q.id];
      if (ans != null) {
        catScores[q.category] = (catScores[q.category] ?? 0) + ans.riskScore;
      }
    }

    final maxScore = (_questions.length * 3) + 2;
    final pct = totalScore / maxScore;

    String riskLevel;
    if (pct < 0.3) riskLevel = AppConstants.riskLow;
    else if (pct < 0.6) riskLevel = AppConstants.riskModerate;
    else riskLevel = AppConstants.riskHigh;

    final recommendations = _buildRecommendations(catScores, riskLevel);

    final result = SelfAssessmentResult(
      id: const Uuid().v4(),
      date: DateTime.now(),
      totalScore: totalScore,
      riskLevel: riskLevel,
      categoryScores: catScores,
      recommendations: recommendations,
    );

    provider.saveAssessmentResult(result);
    setState(() { _result = result; _isCompleted = true; });
  }

  List<String> _buildRecommendations(Map<String, int> cats, String risk) {
    final recs = <String>[];
    if ((cats['activity'] ?? 0) >= 2) recs.add('Augmentez votre activité physique à au moins 150 min/semaine');
    if ((cats['nutrition'] ?? 0) >= 3) recs.add('Améliorez votre alimentation : moins de sel, sucre et aliments transformés');
    if ((cats['smoking'] ?? 0) >= 2) recs.add('Arrêtez de fumer : cela réduit significativement votre risque cardiovasculaire');
    if ((cats['stress'] ?? 0) >= 2) recs.add('Pratiquez des techniques de gestion du stress (méditation, yoga, relaxation)');
    if ((cats['family_history'] ?? 0) >= 2) recs.add('Consultez votre médecin pour un dépistage préventif régulier');
    if (risk == AppConstants.riskHigh) recs.add('Consultez un médecin rapidement pour une évaluation complète');
    if (recs.isEmpty) recs.add('Maintenez vos bonnes habitudes de vie et continuez à vous surveiller');
    return recs;
  }

  void _reset() {
    setState(() {
      _currentIndex = 0;
      _answers.clear();
      _isCompleted = false;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isCompleted && _result != null) {
      return _buildResultPage(context, _result!, isDark);
    }

    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final user = provider.currentUser!;
    final age = AppUtils.calculateAge(user.dateOfBirth);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppAppBar(
        title: const Text('Bilan de santé'),
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(10), child: Text(
            'Répondez à ces questions pour évaluer votre santé ',
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.white : AppColors.textSecondary,
              fontSize: 14,
            ),
          )),
          // Progress bar
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${_currentIndex + 1} sur ${_questions.length}',
                      style: AppTextStyles.bodySmall),
                    Text('${(progress * 100).toInt()}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent, fontWeight: FontWeight.w700,
                      )),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('${user.firstName}, $age ans',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),

          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  StatusBadge(
                    label: _categoryLabel(q.category),
                    color: _categoryColor(q.category),
                  ),
                  const SizedBox(height: 16),
                  Text(q.question, style: AppTextStyles.h3.copyWith(color: isDark ? AppColors.white : AppColors.textPrimary)),
                  const SizedBox(height: 24),

                  // Options
                  ...q.options.map((opt) {
                    final isSelected = _answers[q.id]?.id == opt.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _selectOption(opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.08)
                                : (isDark ? AppColors.darkSurface : AppColors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(opt.label, style: AppTextStyles.body.copyWith(
                                  color: isSelected
                                      ? (isDark ? AppColors.success : AppColors.primary)
                                      : (isDark ? AppColors.darkText : AppColors.textPrimary),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                )),
                              ),
                              if (opt.riskScore == 0) const Icon(Icons.star, color: AppColors.success, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Next button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: PrimaryButton(
              label: _currentIndex < _questions.length - 1 ? 'Suivant' : 'Voir mon résultat',
              onPressed: _answers[q.id] != null ? _next : null,
              icon: _currentIndex < _questions.length - 1 ? Icons.arrow_forward : Icons.check_circle,
              color: _answers[q.id] != null ? AppColors.primary : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPage(BuildContext context, SelfAssessmentResult result, bool isDark) {
    final riskColor = AppUtils.riskColor(result.riskLevel);
    final riskLabel = AppUtils.riskLabel(result.riskLevel);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        title: const Text('Résultat du bilan'),
        actions: [
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refaire'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Risk result card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [riskColor.withOpacity(0.15), riskColor.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15), shape: BoxShape.circle,
                      border: Border.all(color: riskColor.withOpacity(0.4), width: 2),
                    ),
                    child: Icon(_riskIcon(result.riskLevel), color: riskColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(riskLabel, style: AppTextStyles.h2.copyWith(color: riskColor)),
                  const SizedBox(height: 8),
                  Text(
                    'Score : ${result.totalScore} points',
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _riskDescription(result.riskLevel),
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category scores
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analyse par catégorie', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  ...result.categoryScores.entries.map((e) {
                    final max = _categoryMax(e.key);
                    final pct = e.value / max;
                    final color = pct < 0.3 ? AppColors.success :
                    pct < 0.66 ? AppColors.warning : AppColors.error;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_categoryLabel(e.key), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              Text('${e.value}/$max', style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recommendations
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.recommend, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text('Recommandations', style: AppTextStyles.h4),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...result.recommendations.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text('${e.key + 1}', style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent, fontWeight: FontWeight.w700,
                            )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value, style: AppTextStyles.body.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, height: 1.5,
                        ))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _riskIcon(String risk) {
    switch (risk) {
      case AppConstants.riskLow: return Icons.check_circle;
      case AppConstants.riskModerate: return Icons.warning_amber;
      case AppConstants.riskHigh: return Icons.dangerous;
      default: return Icons.help_outline;
    }
  }

  String _riskDescription(String risk) {
    switch (risk) {
      case AppConstants.riskLow:
        return 'Votre profil de risque est faible. Continuez à maintenir vos bonnes habitudes de vie et effectuez des bilans réguliers.';
      case AppConstants.riskModerate:
        return 'Votre profil présente un risque modéré. Quelques changements de style de vie et une consultation médicale sont recommandés.';
      case AppConstants.riskHigh:
        return 'Votre profil présente un risque élevé. Consultez un médecin rapidement pour une évaluation complète et un suivi adapté.';
      default:
        return '';
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'activity': return 'Activité physique';
      case 'nutrition': return 'Alimentation';
      case 'smoking': return 'Tabagisme';
      case 'stress': return 'Gestion du stress';
      case 'family_history': return 'Antécédents familiaux';
      case 'lifestyle': return 'Hygiène de vie';
      default: return cat;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'activity': return AppColors.accent;
      case 'nutrition': return AppColors.success;
      case 'smoking': return AppColors.error;
      case 'stress': return AppColors.warning;
      case 'family_history': return AppColors.primary;
      case 'lifestyle': return AppColors.info;
      default: return AppColors.textHint;
    }
  }

  int _categoryMax(String cat) {
    switch (cat) {
      case 'nutrition': return 9; // 3 questions × 3
      case 'activity': return 3;
      case 'smoking': return 3;
      case 'stress': return 3;
      case 'family_history': return 3;
      case 'lifestyle': return 3;
      default: return 3;
    }
  }
}