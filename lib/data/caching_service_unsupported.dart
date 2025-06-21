import 'package:pobeda_app/models/product_detail.dart';
import 'package:pobeda_app/models/sheet_data.dart';

class CachingService {
  Future<void> cacheMainData(List<SheetData> data) async {}

  Future<List<SheetData>?> getCachedMainData() async => null;

  Future<DateTime?> getLastMainDataCacheTimestamp() async => null;

  Future<void> cacheDetails(
      String sheetTitle, List<ProductDetail> details) async {}

  Future<List<ProductDetail>?> getCachedDetails(String sheetTitle) async =>
      null;
}
