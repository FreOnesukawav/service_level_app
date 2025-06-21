import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:pobeda_app/data/data_repository.dart';
import 'package:pobeda_app/models/sheet_data.dart';
import 'package:pobeda_app/ui/detail_screen.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final DataRepository _repository = DataRepository();
  List<SheetData>? _data;
  String? _error;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      print("Hourly auto-refresh triggered.");
      _loadData(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final data = await _repository.getMainData(forceRefresh: forceRefresh);
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
        title: const Text('Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(forceRefresh: true),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(forceRefresh: true),
              child: const Text('Try Again'),
            )
          ],
        ),
      );
    }
    if (_data == null || _data!.isEmpty) {
      return const Center(child: Text('No data found.'));
    }

    final sortedData = _data!.reversed.toList();

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: AnimationLimiter(
        child: GridView.builder(
          reverse: true,
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.0,
          ),
          itemCount: sortedData.length,
          itemBuilder: (context, index) {
            final itemData = sortedData[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailScreen(sheetData: itemData),
                        ),
                      );
                    },
                    child: _buildDataCard(itemData),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDataCard(SheetData data) {
    final dayOfWeek = DateFormat.EEEE('ru_RU').format(data.parsedDate);

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              data.date,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayOfWeek,
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHorizontalCategoryItem(
                  Icons.ac_unit,
                  'Охл',
                  data.ohladeniePercent,
                  Colors.blue,
                ),
                _buildHorizontalCategoryItem(
                  Icons.severe_cold,
                  'Зам',
                  data.zamorozkaPercent,
                  Colors.lightBlue,
                ),
                _buildHorizontalCategoryItem(
                  Icons.local_florist,
                  'ФРОВ',
                  data.frovPercent,
                  Colors.green,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCategoryItem(
      IconData icon, String label, double percentage, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(2)}%',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }
}
