import 'package:flutter/material.dart';
import 'package:pobeda_app/data/data_repository.dart';
import 'package:pobeda_app/models/product_detail.dart';
import 'package:pobeda_app/models/sheet_data.dart';

enum _SortOrder { ascending, descending, none }

class DetailScreen extends StatefulWidget {
  final SheetData sheetData;

  const DetailScreen({super.key, required this.sheetData});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataRepository _repository = DataRepository();
  late Future<List<ProductDetail>> _detailsFuture;

  List<ProductDetail> _frovItems = [];
  List<ProductDetail> _zamorozkaItems = [];
  List<ProductDetail> _ohladenieItems = [];

  // State for sorting and filtering
  _SortOrder _currentSortOrder = _SortOrder.none;
  bool _showOnlyOutOfTolerance = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _detailsFuture = _repository.getDetailsForSheet(widget.sheetData.date);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update tab colors
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _filterData(List<ProductDetail> details) {
    _frovItems = details.where((d) => d.category.toUpperCase() == 'F').toList();
    _zamorozkaItems =
        details.where((d) => d.category.toUpperCase() == 'З').toList();
    _ohladenieItems =
        details.where((d) => d.category.toUpperCase() == 'Ф').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали: ${widget.sheetData.date}'),
      ),
      body: FutureBuilder<List<ProductDetail>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No detailed data found.'));
          } else {
            if (_frovItems.isEmpty &&
                _zamorozkaItems.isEmpty &&
                _ohladenieItems.isEmpty) {
              _filterData(snapshot.data!);
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildTabBar(),
                  _buildFilterControls(),
                  IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildProductList(
                          _getProcessedList(_frovItems, 'F'), 'F'),
                      _buildProductList(
                          _getProcessedList(_zamorozkaItems, 'З'), 'З'),
                      _buildProductList(
                          _getProcessedList(_ohladenieItems, 'Ф'), 'Ф'),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[850],
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white,
        indicator: const BoxDecoration(),
        tabAlignment: TabAlignment.fill,
        tabs: [
          _buildTab("ФРОВ", widget.sheetData.frovPercent, Colors.green),
          _buildTab(
              "Заморозка", widget.sheetData.zamorozkaPercent, Colors.lightBlue),
          _buildTab(
              "Охлажденка", widget.sheetData.ohladeniePercent, Colors.blue),
        ],
      ),
    );
  }

  Tab _buildTab(String title, double percentage, Color color) {
    final isSelected = _tabController.index == _getTabIndex(title);
    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? color : Colors.grey[800],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  int _getTabIndex(String title) {
    switch (title) {
      case 'ФРОВ':
        return 0;
      case 'Заморозка':
        return 1;
      case 'Охлажденка':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text("Сортировка:", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [
                  _currentSortOrder == _SortOrder.ascending,
                  _currentSortOrder == _SortOrder.descending,
                ],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) {
                      _currentSortOrder =
                          _currentSortOrder == _SortOrder.ascending
                              ? _SortOrder.none
                              : _SortOrder.ascending;
                    } else {
                      _currentSortOrder =
                          _currentSortOrder == _SortOrder.descending
                              ? _SortOrder.none
                              : _SortOrder.descending;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 30, minWidth: 40),
                selectedColor: Colors.white,
                color: Colors.white,
                fillColor: Colors.blue.withOpacity(0.2),
                children: const [
                  Icon(Icons.arrow_upward, size: 18),
                  Icon(Icons.arrow_downward, size: 18),
                ],
              ),
            ],
          ),
          Flexible(
            child: CheckboxListTile(
              title: const Text("Не в допуске",
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              value: _showOnlyOutOfTolerance,
              onChanged: (bool? value) {
                setState(() {
                  _showOnlyOutOfTolerance = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  List<ProductDetail> _getProcessedList(
      List<ProductDetail> originalList, String category) {
    List<ProductDetail> processedList = List.from(originalList);

    if (_showOnlyOutOfTolerance) {
      processedList.removeWhere((item) => !_isOutOfTolerance(item, category));
    }

    if (_currentSortOrder != _SortOrder.none) {
      processedList.sort((a, b) {
        if (_currentSortOrder == _SortOrder.ascending) {
          return a.percentage.compareTo(b.percentage);
        } else {
          return b.percentage.compareTo(a.percentage);
        }
      });
    }

    return processedList;
  }

  bool _isOutOfTolerance(ProductDetail item, String category) {
    if (category == 'F') {
      // ФРОВ
      return item.percentage < 90.0;
    } else {
      // Заморозка и Охлажденка
      return item.percentage < 93.0;
    }
  }

  Widget _buildProductList(List<ProductDetail> items, String category) {
    if (items.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Нет продуктов в этой категории.",
            style: TextStyle(color: Colors.white)),
      ));
    }
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        final backgroundColor = _isOutOfTolerance(item, category)
            ? Colors.red.withOpacity(0.2)
            : Colors.green.withOpacity(0.2);
        const textColor = Colors.white;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          title: Text('${item.code} - ${item.name}',
              style: const TextStyle(fontSize: 14, color: Colors.white)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              '${item.percentage.toStringAsFixed(2)}%',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        );
      },
    );
  }
}
