import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pobeda_app/models/product_detail.dart';
import 'package:pobeda_app/models/sheet_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachingService {
  static const _mainDataCacheKey = 'main_data_cache_timestamp';
  static const _mainDataFileName = 'main_data.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  // --- Main Data Cache ---

  Future<void> cacheMainData(List<SheetData> data) async {
    final file = await _getLocalFile(_mainDataFileName);
    final jsonString = jsonEncode(data.map((d) => d.toJson()).toList());
    await file.writeAsString(jsonString);
    await _setMainDataCacheTimestamp();
  }

  Future<List<SheetData>?> getCachedMainData() async {
    try {
      final file = await _getLocalFile(_mainDataFileName);
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => SheetData.fromJson(json)).toList();
    } catch (e) {
      // File not found, etc.
      return null;
    }
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

  // --- Details Cache ---

  String _getDetailsFileName(String sheetTitle) => 'details_$sheetTitle.json';

  Future<void> cacheDetails(
      String sheetTitle, List<ProductDetail> details) async {
    final file = await _getLocalFile(_getDetailsFileName(sheetTitle));
    final jsonString = jsonEncode(details.map((d) => d.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<List<ProductDetail>?> getCachedDetails(String sheetTitle) async {
    try {
      final file = await _getLocalFile(_getDetailsFileName(sheetTitle));
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => ProductDetail.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }
}
