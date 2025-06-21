import 'dart:convert';
import 'package:pobeda_app/models/product_detail.dart';
import 'package:pobeda_app/models/sheet_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachingService {
  final Map<String, String> _webCache = {};
  static const _mainDataCacheKey = 'main_data_cache_timestamp';
  static const _mainDataFileName = 'main_data.json';

  Future<void> cacheMainData(List<SheetData> data) async {
    final jsonString = jsonEncode(data.map((d) => d.toJson()).toList());
    _webCache[_mainDataFileName] = jsonString;
    await _setMainDataCacheTimestamp();
  }

  Future<List<SheetData>?> getCachedMainData() async {
    final contents = _webCache[_mainDataFileName];
    if (contents == null) return null;
    final List<dynamic> jsonList = jsonDecode(contents);
    return jsonList.map((json) => SheetData.fromJson(json)).toList();
  }

  Future<void> _setMainDataCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _mainDataCacheKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastMainDataCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_mainDataCacheKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  String _getDetailsFileName(String sheetTitle) => 'details_$sheetTitle.json';

  Future<void> cacheDetails(
      String sheetTitle, List<ProductDetail> details) async {
    final fileName = _getDetailsFileName(sheetTitle);
    final jsonString = jsonEncode(details.map((d) => d.toJson()).toList());
    _webCache[fileName] = jsonString;
  }

  Future<List<ProductDetail>?> getCachedDetails(String sheetTitle) async {
    final fileName = _getDetailsFileName(sheetTitle);
    final contents = _webCache[fileName];
    if (contents == null) return null;
    final List<dynamic> jsonList = jsonDecode(contents);
    return jsonList.map((json) => ProductDetail.fromJson(json)).toList();
  }
}
