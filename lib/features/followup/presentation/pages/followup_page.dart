import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../services/app_provider.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class FollowUpPage extends StatefulWidget {
  const FollowUpPage({super.key});
  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isHypertension = provider.currentUser?.diseaseType == 'hypertension';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suivi de santé', style: AppTextStyles.h4),
            if (provider.currentUser?.diseaseType != null)
              DiseaseTag(diseaseType: provider.currentUser!.diseaseType!),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddMeasurementSheet(context, isHypertension),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: AppColors.accent, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Graphiques'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ChartsTab(isHypertension: isHypertension),
          _HistoryTab(isHypertension: isHypertension),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeasurementSheet(context, isHypertension),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ajouter une mesure', style: AppTextStyles.button.copyWith(color: Colors.white)),
      ),
    );
  }

  void _showAddMeasurementSheet(BuildContext context, bool isHypertension) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => isHypertension
          ? _HypertensionMeasurementSheet(outerContext: context)
          : _DiabetesMeasurementSheet(outerContext: context),
    );
  }
}

// ─── Charts Tab ───
class _ChartsTab extends StatelessWidget {
  final bool isHypertension;
  const _ChartsTab({required this.isHypertension});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isHypertension) {
      return _buildHypertensionCharts(context, provider, isDark);
    } else {
      return _buildDiabetesCharts(context, provider, isDark);
    }
  }

  Widget _buildHypertensionCharts(BuildContext ctx, AppProvider prov, bool dark) {
    final records = prov.hypertensionRecords.reversed.toList();
    if (records.isEmpty) {
      return const EmptyState(icon: Icons.show_chart, title: 'Aucune mesure enregistrée',
        subtitle: 'Ajoutez votre première mesure pour voir les graphiques');
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSummaryCards(ctx, prov, dark),
        const SizedBox(height: 24),

        // Blood pressure chart
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: AppColors.hypertension, size: 18),
                  const SizedBox(width: 8),
                  Text('Tension artérielle', style: AppTextStyles.h4),
                ],
              ),
              const SizedBox(height: 4),
              Text('${records.length} mesures • 7 derniers jours',
                style: AppTextStyles.bodySmall),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: LineChart(_buildBpChart(records, dark)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _legendItem(AppColors.hypertension, 'Systolique'),
                  const SizedBox(width: 16),
                  _legendItem(AppColors.primary, 'Diastolique'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Heart rate + Temp charts
        Row(
          children: [
            Expanded(child: _miniChart(ctx, 'Fréquence cardiaque', 'bpm', AppColors.error,
              records.map((r) => r.heartRate).toList(), dark)),
            const SizedBox(width: 12),
            Expanded(child: _miniChart(ctx, 'Température', '°C', AppColors.warning,
              records.map((r) => r.temperature).toList(), dark)),
          ],
        ),
      ],
    );
  }

  Widget _buildDiabetesCharts(BuildContext ctx, AppProvider prov, bool dark) {
    final records = prov.diabetesRecords.reversed.toList();
    if (records.isEmpty) {
      return const EmptyState(icon: Icons.show_chart, title: 'Aucune mesure enregistrée',
        subtitle: 'Ajoutez votre première mesure pour voir les graphiques');
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDiabetesSummary(ctx, prov, dark),
        const SizedBox(height: 24),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Text('Glycémie', style: AppTextStyles.h4),
                ],
              ),
              const SizedBox(height: 4),
              Text('${records.length} mesures enregistrées', style: AppTextStyles.bodySmall),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: LineChart(_buildGlucoseChart(records, dark)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _miniChart(ctx, 'Fréquence cardiaque', 'bpm', AppColors.error,
              records.map((r) => r.heartRate).toList(), dark)),
            const SizedBox(width: 12),
            Expanded(child: _miniChart(ctx, 'Température', '°C', AppColors.warning,
              records.map((r) => r.temperature).toList(), dark)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext ctx, AppProvider prov, bool dark) {
    final latest = prov.hypertensionRecords.first;
    return Row(
      children: [
        Expanded(child: MetricCard(
          label: 'TENSION',
          value: '${latest.systolic.toInt()}/${latest.diastolic.toInt()}',
          unit: 'mmHg',
          status: AppUtils.bpStatus(latest.systolic, latest.diastolic),
          statusColor: AppUtils.bpColor(latest.systolic, latest.diastolic),
          icon: Icons.favorite, iconColor: AppColors.hypertension,
        )),
        const SizedBox(width: 12),
        Expanded(child: MetricCard(
          label: 'FRÉQUENCE',
          value: latest.heartRate.toInt().toString(),
          unit: 'bpm',
          status: AppUtils.heartRateStatus(latest.heartRate),
          statusColor: AppUtils.heartRateColor(latest.heartRate),
          icon: Icons.monitor_heart, iconColor: AppColors.error,
        )),
      ],
    );
  }

  Widget _buildDiabetesSummary(BuildContext ctx, AppProvider prov, bool dark) {
    final latest = prov.diabetesRecords.first;
    return Row(
      children: [
        Expanded(child: MetricCard(
          label: 'GLYCÉMIE',
          value: latest.glucoseLevel.toStringAsFixed(2),
          unit: 'g/L',
          status: AppUtils.glucoseStatus(latest.glucoseLevel),
          statusColor: AppUtils.glucoseColor(latest.glucoseLevel),
          icon: Icons.water_drop, iconColor: AppColors.info,
        )),
        const SizedBox(width: 12),
        Expanded(child: MetricCard(
          label: 'FRÉQUENCE',
          value: latest.heartRate.toInt().toString(),
          unit: 'bpm',
          status: AppUtils.heartRateStatus(latest.heartRate),
          statusColor: AppUtils.heartRateColor(latest.heartRate),
          icon: Icons.monitor_heart, iconColor: AppColors.error,
        )),
      ],
    );
  }

  LineChartData _buildBpChart(List<HypertensionRecord> records, bool dark) {
    final spots1 = records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.systolic)).toList();
    final spots2 = records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.diastolic)).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: dark ? AppColors.darkBorder : AppColors.divider, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
          getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: AppTextStyles.caption))),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) {
            final idx = v.toInt();
            if (idx < records.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(AppUtils.formatDateShort(records[idx].measuredAt), style: AppTextStyles.caption),
              );
            }
            return const SizedBox.shrink();
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      minY: 60, maxY: 180,
      lineBarsData: [
        LineChartBarData(
          spots: spots1, color: AppColors.hypertension, barWidth: 2.5,
          dotData: FlDotData(getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
            radius: 4, color: AppColors.hypertension, strokeWidth: 2, strokeColor: Colors.white)),
          belowBarData: BarAreaData(show: true, color: AppColors.hypertension.withOpacity(0.08)),
        ),
        LineChartBarData(
          spots: spots2, color: AppColors.primary, barWidth: 2.5,
          dotData: FlDotData(getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
            radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white)),
          belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.06)),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            s.y.toInt().toString(),
            AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          )).toList(),
        ),
      ),
    );
  }

  LineChartData _buildGlucoseChart(List<DiabetesRecord> records, bool dark) {
    final spots = records.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.glucoseLevel)).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: dark ? AppColors.darkBorder : AppColors.divider, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
          getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: AppTextStyles.caption))),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) {
            final idx = v.toInt();
            if (idx < records.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(AppUtils.formatDateShort(records[idx].measuredAt), style: AppTextStyles.caption),
              );
            }
            return const SizedBox.shrink();
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: AppColors.info, barWidth: 2.5,
          dotData: FlDotData(getDotPainter: (spot, _, __, ___) {
            final color = AppUtils.glucoseColor(spot.y);
            return FlDotCirclePainter(radius: 5, color: color, strokeWidth: 2, strokeColor: Colors.white);
          }),
          belowBarData: BarAreaData(show: true, color: AppColors.info.withOpacity(0.08)),
        ),
      ],
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(y: 1.10, color: AppColors.warning.withOpacity(0.6), strokeWidth: 1,
          dashArray: [4, 4], label: HorizontalLineLabel(show: true, labelResolver: (_) => 'Max normal',
          style: AppTextStyles.caption.copyWith(color: AppColors.warning))),
        HorizontalLine(y: 0.70, color: AppColors.error.withOpacity(0.6), strokeWidth: 1,
          dashArray: [4, 4]),
      ]),
    );
  }

  Widget _miniChart(BuildContext ctx, String title, String unit, Color color, List<double> values, bool dark) {
    final spots = values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final lastVal = values.isNotEmpty ? values.last : 0;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(unit == 'bpm' ? lastVal.toInt().toString() : lastVal.toStringAsFixed(1),
                style: AppTextStyles.h3.copyWith(color: dark ? AppColors.darkText : AppColors.textPrimary)),
              const SizedBox(width: 3),
              Text(unit, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots, color: color, barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ─── History Tab ───
class _HistoryTab extends StatelessWidget {
  final bool isHypertension;
  const _HistoryTab({required this.isHypertension});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isHypertension) {
      final records = provider.hypertensionRecords;
      if (records.isEmpty) {
        return const EmptyState(icon: Icons.history, title: 'Aucune mesure', subtitle: 'Votre historique apparaîtra ici');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildHypertensionItem(context, records[i], isDark),
      );
    } else {
      final records = provider.diabetesRecords;
      if (records.isEmpty) {
        return const EmptyState(icon: Icons.history, title: 'Aucune mesure', subtitle: 'Votre historique apparaîtra ici');
      }
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildDiabetesItem(context, records[i], isDark),
      );
    }
  }

  Widget _buildHypertensionItem(BuildContext context, HypertensionRecord r, bool dark) {
    final bpColor = AppUtils.bpColor(r.systolic, r.diastolic);
    return AppCard(
      border: Border.all(color: bpColor.withOpacity(0.25)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: bpColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite, color: bpColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.systolic.toInt()}/${r.diastolic.toInt()} mmHg',
                      style: AppTextStyles.h3.copyWith(color: dark ? AppColors.darkText : AppColors.textPrimary)),
                    Text(AppUtils.bpStatus(r.systolic, r.diastolic),
                      style: AppTextStyles.bodySmall.copyWith(color: bpColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppUtils.formatDate(r.measuredAt), style: AppTextStyles.caption),
                  Text(AppUtils.formatTimeFromDateTime(r.measuredAt), style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniMetric(Icons.monitor_heart, '${r.heartRate.toInt()} bpm',
                AppUtils.heartRateColor(r.heartRate))),
              Expanded(child: _miniMetric(Icons.thermostat, '${r.temperature.toStringAsFixed(1)} °C',
                AppUtils.temperatureColor(r.temperature))),
              if (r.context.isNotEmpty)
                Expanded(child: _miniMetric(Icons.info_outline, _contextLabel(r.context), AppColors.textHint)),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkBackground : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.comment!, style: AppTextStyles.bodySmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiabetesItem(BuildContext context, DiabetesRecord r, bool dark) {
    final glColor = AppUtils.glucoseColor(r.glucoseLevel);
    return AppCard(
      border: Border.all(color: glColor.withOpacity(0.25)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: glColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.water_drop, color: glColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.glucoseLevel.toStringAsFixed(2)} g/L',
                      style: AppTextStyles.h3.copyWith(color: dark ? AppColors.darkText : AppColors.textPrimary)),
                    Text(AppUtils.glucoseStatus(r.glucoseLevel, fasting: r.context == 'a_jeun'),
                      style: AppTextStyles.bodySmall.copyWith(color: glColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppUtils.formatDate(r.measuredAt), style: AppTextStyles.caption),
                  Text(AppUtils.formatTimeFromDateTime(r.measuredAt), style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniMetric(Icons.monitor_heart, '${r.heartRate.toInt()} bpm',
                AppUtils.heartRateColor(r.heartRate))),
              Expanded(child: _miniMetric(Icons.thermostat, '${r.temperature.toStringAsFixed(1)} °C',
                AppUtils.temperatureColor(r.temperature))),
              Expanded(child: _miniMetric(Icons.info_outline, _diabetesContextLabel(r.context), AppColors.textHint)),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkBackground : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.comment!, style: AppTextStyles.bodySmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniMetric(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _contextLabel(String ctx) {
    switch (ctx) {
      case 'repos': return 'Au repos';
      case 'matin': return 'Matin';
      case 'soir': return 'Soir';
      case 'stress': return 'Stress';
      case 'apres_sport': return 'Après sport';
      default: return ctx;
    }
  }

  String _diabetesContextLabel(String ctx) {
    switch (ctx) {
      case 'a_jeun': return 'À jeun';
      case 'post_prandial': return 'Post-repas';
      case 'apres_sport': return 'Après sport';
      case 'aleatoire': return 'Aléatoire';
      default: return ctx;
    }
  }
}

// ─── Hypertension Measurement Sheet ───
class _HypertensionMeasurementSheet extends StatefulWidget {
  final BuildContext outerContext;
  const _HypertensionMeasurementSheet({required this.outerContext});

  @override
  State<_HypertensionMeasurementSheet> createState() => _HypertensionMeasurementSheetState();
}

class _HypertensionMeasurementSheetState extends State<_HypertensionMeasurementSheet> {
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String _context = 'repos';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _contextOptions = [
    {'value': 'repos', 'label': 'Au repos', 'icon': Icons.airline_seat_recline_normal},
    {'value': 'matin', 'label': 'Matin', 'icon': Icons.wb_sunny_outlined},
    {'value': 'soir', 'label': 'Soir', 'icon': Icons.nights_stay_outlined},
    {'value': 'stress', 'label': 'Stress', 'icon': Icons.psychology_outlined},
    {'value': 'apres_sport', 'label': 'Après sport', 'icon': Icons.fitness_center},
  ];

  @override
  void dispose() {
    _systolicCtrl.dispose(); _diastolicCtrl.dispose();
    _heartRateCtrl.dispose(); _temperatureCtrl.dispose(); _commentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_systolicCtrl.text.isEmpty || _diastolicCtrl.text.isEmpty) {
      AppUtils.showSnackBar(widget.outerContext, 'Renseignez la tension artérielle', isError: true);
      return;
    }
    final systolic = double.tryParse(_systolicCtrl.text) ?? 0;
    final diastolic = double.tryParse(_diastolicCtrl.text) ?? 0;
    final heartRate = double.tryParse(_heartRateCtrl.text) ?? 72;
    final temperature = double.tryParse(_temperatureCtrl.text) ?? 37.0;

    if (systolic < 60 || systolic > 250 || diastolic < 40 || diastolic > 150) {
      AppUtils.showSnackBar(widget.outerContext, 'Valeurs de tension non valides', isError: true);
      return;
    }

    final measuredAt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute);

    final record = HypertensionRecord(
      id: const Uuid().v4(),
      userId: widget.outerContext.read<AppProvider>().currentUser!.id,
      systolic: systolic, diastolic: diastolic,
      heartRate: heartRate, temperature: temperature,
      measuredAt: measuredAt, comment: _commentCtrl.text, context: _context,
    );

    widget.outerContext.read<AppProvider>().addHypertensionRecord(record);
    AppUtils.showSnackBar(widget.outerContext, 'Mesure enregistrée avec succès !');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.hypertension.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite, color: AppColors.hypertension, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nouvelle mesure', style: AppTextStyles.h4),
                      Text('Tension artérielle & signes vitaux', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),

          const AppDivider(),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blood pressure - main field
                  _buildSectionLabel('Tension artérielle *', AppColors.hypertension),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          controller: _systolicCtrl,
                          label: 'Systolique',
                          hint: '130',
                          unit: 'mmHg',
                          color: AppColors.hypertension,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('/', style: AppTextStyles.h1.copyWith(color: AppColors.textHint)),
                      ),
                      Expanded(
                        child: _buildNumberField(
                          controller: _diastolicCtrl,
                          label: 'Diastolique',
                          hint: '80',
                          unit: 'mmHg',
                          color: AppColors.primary,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                    ],
                  ),

                  // Live preview
                  if (_systolicCtrl.text.isNotEmpty && _diastolicCtrl.text.isNotEmpty)
                    _buildBpPreview(),

                  const SizedBox(height: 20),

                  // Heart rate & Temperature
                  _buildSectionLabel('Signes vitaux', AppColors.error),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          controller: _heartRateCtrl,
                          label: 'Fréquence cardiaque',
                          hint: '72',
                          unit: 'bpm',
                          color: AppColors.error,
                          icon: Icons.monitor_heart_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberField(
                          controller: _temperatureCtrl,
                          label: 'Température',
                          hint: '37.0',
                          unit: '°C',
                          color: AppColors.warning,
                          icon: Icons.thermostat_outlined,
                          isDecimal: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Context
                  _buildSectionLabel('Contexte', AppColors.primary),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _contextOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final opt = _contextOptions[i];
                        final isSelected = _context == opt['value'];
                        return GestureDetector(
                          onTap: () => setState(() => _context = opt['value'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : AppColors.background),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border)),
                            ),
                            child: Row(
                              children: [
                                Icon(opt['icon'] as IconData,
                                  size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(opt['label'] as String,
                                  style: AppTextStyles.bodySmall.copyWith(
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

                  const SizedBox(height: 20),

                  // Date & Time
                  _buildSectionLabel('Date et heure', AppColors.primary),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker(context, isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTimePicker(context, isDark)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Comment
                  _buildSectionLabel('Commentaire (optionnel)', AppColors.textSecondary),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Ex: après repos, prise de médicament...',
                      prefixIcon: Icon(Icons.comment_outlined, size: 20),
                    ),
                  ),

                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Enregistrer la mesure',
                    onPressed: _save,
                    icon: Icons.save_outlined,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: AppTextStyles.label.copyWith(color: color, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String unit,
    required Color color,
    required IconData icon,
    bool isDecimal = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : color.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            prefixIcon: Icon(icon, color: color, size: 18),
            suffixText: unit,
            suffixStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          style: AppTextStyles.h4.copyWith(
            color: isDark ? AppColors.darkText : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBpPreview() {
    final sys = double.tryParse(_systolicCtrl.text);
    final dia = double.tryParse(_diastolicCtrl.text);
    if (sys == null || dia == null) return const SizedBox.shrink();

    final status = AppUtils.bpStatus(sys, dia);
    final color = AppUtils.bpColor(sys, dia);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Text(status, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(AppUtils.formatDate(_selectedDate), style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: _selectedTime);
        if (picked != null) setState(() => _selectedTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(AppUtils.formatTime(_selectedTime), style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}

// ─── Diabetes Measurement Sheet ───
class _DiabetesMeasurementSheet extends StatefulWidget {
  final BuildContext outerContext;
  const _DiabetesMeasurementSheet({required this.outerContext});

  @override
  State<_DiabetesMeasurementSheet> createState() => _DiabetesMeasurementSheetState();
}

class _DiabetesMeasurementSheetState extends State<_DiabetesMeasurementSheet> {
  final _glucoseCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String _context = 'a_jeun';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final _contextOptions = [
    {'value': 'a_jeun', 'label': 'À jeun', 'icon': Icons.bedtime_outlined},
    {'value': 'post_prandial', 'label': 'Post-repas', 'icon': Icons.restaurant},
    {'value': 'apres_sport', 'label': 'Après sport', 'icon': Icons.fitness_center},
    {'value': 'aleatoire', 'label': 'Aléatoire', 'icon': Icons.shuffle},
  ];

  @override
  void dispose() {
    _glucoseCtrl.dispose(); _heartRateCtrl.dispose();
    _temperatureCtrl.dispose(); _commentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_glucoseCtrl.text.isEmpty) {
      AppUtils.showSnackBar(widget.outerContext, 'Renseignez la glycémie', isError: true);
      return;
    }
    final glucose = double.tryParse(_glucoseCtrl.text) ?? 0;
    if (glucose < 0.1 || glucose > 6.0) {
      AppUtils.showSnackBar(widget.outerContext, 'Valeur de glycémie non valide (0.1 - 6.0 g/L)', isError: true);
      return;
    }

    final heartRate = double.tryParse(_heartRateCtrl.text) ?? 72;
    final temperature = double.tryParse(_temperatureCtrl.text) ?? 37.0;
    final measuredAt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute);

    final record = DiabetesRecord(
      id: const Uuid().v4(),
      userId: widget.outerContext.read<AppProvider>().currentUser!.id,
      glucoseLevel: glucose, heartRate: heartRate, temperature: temperature,
      measuredAt: measuredAt, comment: _commentCtrl.text, context: _context,
    );

    widget.outerContext.read<AppProvider>().addDiabetesRecord(record);
    AppUtils.showSnackBar(widget.outerContext, 'Mesure enregistrée avec succès !');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border, borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nouvelle mesure', style: AppTextStyles.h4),
                      Text('Glycémie & signes vitaux', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
          ),
          const AppDivider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glucose
                  _sectionLabel('Glycémie *', AppColors.info),
                  const SizedBox(height: 10),
                  _numberField(controller: _glucoseCtrl, label: 'Glycémie', hint: '0.95',
                    unit: 'g/L', color: AppColors.info, icon: Icons.water_drop_outlined, isDecimal: true),

                  if (_glucoseCtrl.text.isNotEmpty) _glucosePreview(),

                  const SizedBox(height: 20),
                  _sectionLabel('Signes vitaux', AppColors.error),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _numberField(controller: _heartRateCtrl, label: 'Fréquence', hint: '72',
                        unit: 'bpm', color: AppColors.error, icon: Icons.monitor_heart_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _numberField(controller: _temperatureCtrl, label: 'Température', hint: '37.0',
                        unit: '°C', color: AppColors.warning, icon: Icons.thermostat_outlined, isDecimal: true)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Contexte', AppColors.primary),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _contextOptions.map((opt) {
                      final isSelected = _context == opt['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _context = opt['value'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : AppColors.background),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(opt['icon'] as IconData, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(opt['label'] as String, style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Date et heure', AppColors.primary),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _datePicker(context, isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _timePicker(context, isDark)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Commentaire (optionnel)', AppColors.textSecondary),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentCtrl, maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Ex: à jeun depuis 8h, repas copieux...',
                      prefixIcon: Icon(Icons.comment_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Enregistrer la mesure',
                    onPressed: _save, icon: Icons.save_outlined, color: AppColors.accent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: AppTextStyles.label.copyWith(color: color, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String unit,
    required Color color,
    required IconData icon,
    bool isDecimal = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : color.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.3))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5)),
            prefixIcon: Icon(icon, color: color, size: 18),
            suffixText: unit,
            suffixStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          style: AppTextStyles.h4.copyWith(
            color: isDark ? AppColors.darkText : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _glucosePreview() {
    final g = double.tryParse(_glucoseCtrl.text);
    if (g == null) return const SizedBox.shrink();
    final status = AppUtils.glucoseStatus(g, fasting: _context == 'a_jeun');
    final color = AppUtils.glucoseColor(g);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Text(status, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _datePicker(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(AppUtils.formatDate(_selectedDate), style: AppTextStyles.body),
        ]),
      ),
    );
  }

  Widget _timePicker(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: _selectedTime);
        if (picked != null) setState(() => _selectedTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.access_time, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(AppUtils.formatTime(_selectedTime), style: AppTextStyles.body),
        ]),
      ),
    );
  }
}