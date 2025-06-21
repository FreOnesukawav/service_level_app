import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pobeda_app/data/data_repository.dart';
import 'package:pobeda_app/models/sheet_data.dart';

enum _StatsPeriod { day, week, month }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DataRepository _repository = DataRepository();
  List<SheetData>? _data;
  String? _error;
  bool _isLoading = true;

  _StatsPeriod _selectedPeriod = _StatsPeriod.day;

  // State for legend visibility
  final Map<String, bool> _seriesVisibility = {
    'Охлажденка': true,
    'Заморозка': true,
    'ФРОВ': true,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      // getMainData returns data sorted newest to oldest. Let's keep it that way (newest first)
      final data = await _repository.getMainData(forceRefresh: false);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_data == null || _data!.isEmpty) {
      return const Center(child: Text('Нет данных для статистики.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildComparisonSection(),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildLegend(),
                const SizedBox(height: 20),
                Expanded(child: _buildNewChart()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Column(
      children: [
        _buildComparisonControls(),
        const SizedBox(height: 16),
        Expanded(child: _buildComparisonCards()),
      ],
    );
  }

  Widget _buildComparisonControls() {
    return ToggleButtons(
      isSelected: _StatsPeriod.values.map((p) => p == _selectedPeriod).toList(),
      onPressed: (index) {
        setState(() {
          _selectedPeriod = _StatsPeriod.values[index];
        });
      },
      borderRadius: BorderRadius.circular(8),
      selectedColor: Colors.white,
      color: Colors.white70,
      fillColor: Colors.blue.withOpacity(0.3),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('День'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Неделя'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Месяц'),
        ),
      ],
    );
  }

  Widget _buildComparisonCards() {
    if (_data == null || _data!.length < 2) {
      return const Center(child: Text("Недостаточно данных для сравнения"));
    }

    List<SheetData> currentPeriodData;
    List<SheetData> previousPeriodData;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case _StatsPeriod.day:
        currentPeriodData = [_data![0]];
        previousPeriodData = [_data![1]];
        break;
      case _StatsPeriod.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        currentPeriodData =
            _data!.where((d) => d.parsedDate.isAfter(startOfWeek)).toList();
        previousPeriodData = _data!
            .where((d) =>
                d.parsedDate
                    .isAfter(startOfWeek.subtract(const Duration(days: 7))) &&
                d.parsedDate.isBefore(startOfWeek))
            .toList();
        break;
      case _StatsPeriod.month:
        final startOfMonth = DateTime(now.year, now.month, 1);
        currentPeriodData =
            _data!.where((d) => d.parsedDate.isAfter(startOfMonth)).toList();
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        previousPeriodData = _data!
            .where((d) =>
                d.parsedDate.isAfter(prevMonth) &&
                d.parsedDate.isBefore(startOfMonth))
            .toList();
        break;
    }

    if (currentPeriodData.isEmpty || previousPeriodData.isEmpty) {
      return const Center(
          child: Text("Нет данных за предыдущий период для сравнения"));
    }

    final currentOhl = _getAverageForPeriod(currentPeriodData, 'Охлажденка');
    final prevOhl = _getAverageForPeriod(previousPeriodData, 'Охлажденка');
    final changeOhl = currentOhl - prevOhl;

    final currentZam = _getAverageForPeriod(currentPeriodData, 'Заморозка');
    final prevZam = _getAverageForPeriod(previousPeriodData, 'Заморозка');
    final changeZam = currentZam - prevZam;

    final currentFrov = _getAverageForPeriod(currentPeriodData, 'ФРОВ');
    final prevFrov = _getAverageForPeriod(previousPeriodData, 'ФРОВ');
    final changeFrov = currentFrov - prevFrov;

    return Row(
      children: [
        Expanded(
          child: _buildComparisonCard(
              "Охлажденка", currentOhl, changeOhl, Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildComparisonCard(
              "Заморозка", currentZam, changeZam, Colors.lightBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
            child: _buildComparisonCard(
                "ФРОВ", currentFrov, changeFrov, Colors.green)),
      ],
    );
  }

  double _getAverageForPeriod(List<SheetData> data, String category) {
    if (data.isEmpty) return 0.0;
    double total = 0;
    for (var item in data) {
      switch (category) {
        case 'Охлажденка':
          total += item.ohladeniePercent;
          break;
        case 'Заморозка':
          total += item.zamorozkaPercent;
          break;
        case 'ФРОВ':
          total += item.frovPercent;
          break;
      }
    }
    return total / data.length;
  }

  Widget _buildComparisonCard(
      String title, double value, double change, Color color) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 16)),
            const SizedBox(height: 8),
            Text('${value.toStringAsFixed(2)}%',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Placeholder for arrow and change
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  change > 0
                      ? Icons.arrow_upward
                      : (change < 0 ? Icons.arrow_downward : Icons.remove),
                  color: change > 0
                      ? Colors.green
                      : (change < 0 ? Colors.red : Colors.grey),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: change > 0
                        ? Colors.green
                        : (change < 0 ? Colors.red : Colors.grey),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _seriesVisibility.keys.map((String name) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _seriesVisibility[name] = !_seriesVisibility[name]!;
              });
            },
            child: Row(
              children: [
                Icon(
                  _seriesVisibility[name]!
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: _getColorForSeries(name),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    color: _seriesVisibility[name]!
                        ? Colors.white
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewChart() {
    if (_data == null || _data!.isEmpty) {
      return const Center(child: Text('Нет данных для графика.'));
    }

    // We need data for the last 5 weekdays.
    // Let's find the most recent weekday data and go back 5 days from there.
    final recentData = _data!.reversed.toList(); // newest last

    final ohlData = <FlSpot>[];
    final zamData = <FlSpot>[];
    final frovData = <FlSpot>[];

    final weekDayData = recentData.where((d) {
      final weekDay = d.parsedDate.weekday;
      return weekDay >= 1 && weekDay <= 5;
    }).toList();

    final last5DaysData = weekDayData.length > 5
        ? weekDayData.sublist(weekDayData.length - 5)
        : weekDayData;

    for (var i = 0; i < last5DaysData.length; i++) {
      final item = last5DaysData[i];
      final dayIndex = (i).toDouble();

      if (_seriesVisibility['Охлажденка']!) {
        ohlData.add(FlSpot(dayIndex, item.ohladeniePercent));
      }
      if (_seriesVisibility['Заморозка']!) {
        zamData.add(FlSpot(dayIndex, item.zamorozkaPercent));
      }
      if (_seriesVisibility['ФРОВ']!) {
        frovData.add(FlSpot(dayIndex, item.frovPercent));
      }
    }

    final List<LineChartBarData> lineBarsData = [
      if (ohlData.isNotEmpty) _lineBarData(ohlData, Colors.blue, 'Охлажденка'),
      if (zamData.isNotEmpty)
        _lineBarData(zamData, Colors.lightBlue, 'Заморозка'),
      if (frovData.isNotEmpty) _lineBarData(frovData, Colors.green, 'ФРОВ'),
    ];

    double minVal = 100;
    double maxVal = 0;
    final allSpots = [...ohlData, ...zamData, ...frovData];
    if (allSpots.isNotEmpty) {
      minVal = allSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxVal = allSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    }

    return LineChart(
      LineChartData(
        minY: (minVal - 1).floorToDouble(),
        maxY: (maxVal + 1).ceilToDouble(),
        lineBarsData: lineBarsData,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.left);
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < last5DaysData.length) {
                  final date = last5DaysData[value.toInt()].parsedDate;
                  final dayOfWeek = DateFormat.E('ru_RU').format(date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(dayOfWeek,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                  color: Colors.white24, strokeWidth: 1, dashArray: [5, 5]);
            },
            getDrawingVerticalLine: (value) {
              return const FlLine(
                  color: Colors.white24, strokeWidth: 1, dashArray: [5, 5]);
            }),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final barData = spot.bar;
                String seriesName = '';
                if (barData.color == Colors.blue) seriesName = 'Охлажденка';
                if (barData.color == Colors.lightBlue) seriesName = 'Заморозка';
                if (barData.color == Colors.green) seriesName = 'ФРОВ';

                return LineTooltipItem(
                  '$seriesName\n${spot.y.toStringAsFixed(2)}%',
                  TextStyle(color: barData.color),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineBarData(
      List<FlSpot> spots, Color color, String seriesName) {
    if (!_seriesVisibility[seriesName]!) {
      return LineChartBarData(spots: [], color: Colors.transparent);
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Color _getColorForSeries(String seriesName) {
    switch (seriesName) {
      case 'Охлажденка':
        return Colors.blue;
      case 'Заморозка':
        return Colors.lightBlue;
      case 'ФРОВ':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
