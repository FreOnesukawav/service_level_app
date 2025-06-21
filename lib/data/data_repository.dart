import 'package:gsheets/gsheets.dart';
import 'package:intl/intl.dart';
import 'package:pobeda_app/models/sheet_data.dart';
import 'package:pobeda_app/models/product_detail.dart';
import 'package:pobeda_app/data/caching_service.dart';

class DataRepository {
  final _networkService = _NetworkService();
  final _cachingService = CachingService();

  Future<List<SheetData>> getMainData({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final lastCacheTime =
          await _cachingService.getLastMainDataCacheTimestamp();
      if (lastCacheTime != null &&
          DateTime.now().difference(lastCacheTime).inHours < 1) {
        final cachedData = await _cachingService.getCachedMainData();
        if (cachedData != null && cachedData.isNotEmpty) {
          print("Returning main data from cache.");
          return cachedData;
        }
      }
    }

    print("Fetching main data from network.");
    final networkData = await _networkService.fetchData();
    await _cachingService.cacheMainData(networkData);
    return networkData;
  }

  Future<List<ProductDetail>> getDetailsForSheet(String sheetTitle) async {
    final cachedDetails = await _cachingService.getCachedDetails(sheetTitle);
    if (cachedDetails != null) {
      print("Returning details for '$sheetTitle' from cache.");
      return cachedDetails;
    }

    print("Fetching details for '$sheetTitle' from network.");
    final networkDetails =
        await _networkService.fetchDetailsForSheet(sheetTitle);
    await _cachingService.cacheDetails(sheetTitle, networkDetails);
    return networkDetails;
  }
}

class _NetworkService {
  static const _credentials = r'''
{
  "type": "service_account",
  "project_id": "gen-lang-client-0510029218",
  "private_key_id": "54cf37162c397ece80ef576c6cdb8b415488ae7b",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCevPJ32p7CYA0b\nlSdsONW6YS1AVVDkct5anEBJBwsG3eK/+y91BwuJmEKGZau78XY3I6ozu4hefHN3\nNmLxNSOHP06dCckqY8wnWFrcb2ELBIXGU1YT1uEMSu035tlpxmYvfX6d4yCbrPQy\nJ1M58cioTXVDiHTrnYaxUv61RFSNtX8geXX44+1AUAcFlJ2IHvLGb9Va+FsjBsdS\n9nfzhytx745aqNjO7K1EWRC8kJ636zy1/pAjZTzLU/HcvMXdsWi8yl7fkBOyFMEK\nJ4J/F04OMbfMMhLGYRjlRWhHwqdCa57YvxY3uBuAiA5S95aoZ8lta2D4A/J5w+7K\nIA3gl4JvAgMBAAECggEACDlI5ND+2XWwKnGD53wkBVsvxNTCIRqa80uoLhc6myku\nPphBjLtH/eGehB6K5UgxVBtnVqw11AB4ABOF9QRILsgCIsV+TT8xflIMhCtdCGqp\n/mzLIrH9o6QcYlzjfumF/ppuhm/K6opa4823wj4I7NKsNG9U8IGzvI/MnX6kC1mf\nVB8bRTw4ZdYTtSemfORICbufLF8h/0W3E65bVcg59ta3X+F9YVY5HGqG2yYWNH4H\ncmTizN9yBtNcZCkAaYg8i8ROWqQ56r97dtcs2AFh9WS70gqJ0aM+g5WLR12kqsQV\nO3MV0Uwjs8Dibw8Ro/chY2gcUCI6x0Q9PSkHsSBioQKBgQDS+Y3LAORjzHVYgfuz\nxcZO7QVL/7ZL9Tud/s8CVas6tNaAFkVeG8fPlmdT6vNdUP1E/nnriEBhfTv/bs0e\nhh8oSyAhjOCNDS82XqpLUwHjrjHp1Ppdyw8/30oM74R2IvxTDAwhsOMMCFLWjTFh\nP9EjpuUqehTezTO/rBFjEh0osQKBgQDAnXql5CnlQydrBomtXfcGjkp3hRII7Czl\nFai2i8OjV6gq+HYrVC6wFynbU2w6/huWotg2kE+lyKxeesGxVzMBrgRBpW375Bf9\nKlN6rvgsoS164fBbqgN/Qg838knNAW8lOxHMHdDhl5gYL04kjIng5sHdEn4zbvCM\na4k7xo4lHwKBgCJH7JNU5MeWnGayUEzo0Q1YFClCNsPm6DYHBmoRs44JfmU3uTPO\nfcwsW0PWhI7gLxc75mGwNQ3iRJJ/1ZKlJoDsnB73fjFNOCO0hCVTKpZtYqzlL314\nFlVBmg26CaMMkkWISpxa2rnEzHkSXji4HuqVHt2lEqkVXNhDRFv9wIExAoGAFahf\nZxHNqCqx3vXgOy8qnIEZXHEJAxnTPnr9+nCisdYkYZiIaPzRNxmTqkaqD8QMxBZR\na2k0m3aB8ymoZ9FfOdwgPGVmhYEzNVMyCcRswU/qNjv7c8MdG40I+whyRevYXH5U\n1PexSfxqrKV9Ct0Gj9RCjiILMKtTvuZEiwUbbI8CgYBUf8yys/g/jABxtWLdvvJ5\nS5yqiwyFtJFJm+mog4xjTcvPGwoXT2pSbrrXVZNXu/SNjXzabkm6LQmb+CqWLnxs\nIMDVpP+iOqlqoLB7yX+7mZAns9kmHtaLGrwWZ2WRPhyt47w/S2nftdde19wd1tJM\nKiWT3MISTEtbojK9N1IhAg==\n-----END PRIVATE KEY-----\n",
  "client_email": "gsheets@gen-lang-client-0510029218.iam.gserviceaccount.com",
  "client_id": "107407762234686024820",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/gsheets%40gen-lang-client-0510029218.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  static const _spreadsheetId = '1RmGAJygQQjAY2y4JKiPkJjLSbArIcpTlX2dbTSQLMnI';

  Future<List<SheetData>> fetchData() async {
    try {
      final gsheets = GSheets(_credentials);
      final ss = await gsheets.spreadsheet(_spreadsheetId);

      var allSheetData = <SheetData>[];

      for (var sheet in ss.sheets) {
        double ohladenieTotal = 0;
        int ohladenieCount = 0;
        double zamorozkaTotal = 0;
        int zamorozkaCount = 0;
        double frovTotal = 0;
        int frovCount = 0;

        final values =
            await sheet.values.allRows(fromRow: 2); // Skip header row

        for (var row in values) {
          if (row.length > 11) {
            final category = row[4]; // Column E
            final percentageStr = row[11]; // Column L

            final percentage =
                double.tryParse(percentageStr.replaceAll(',', '.')) ?? 0.0;

            final cappedPercentage = percentage > 100.0 ? 100.0 : percentage;

            switch (category.toUpperCase()) {
              case 'Ф':
                ohladenieTotal += cappedPercentage;
                ohladenieCount++;
                break;
              case 'З':
                zamorozkaTotal += cappedPercentage;
                zamorozkaCount++;
                break;
              case 'F':
                frovTotal += cappedPercentage;
                frovCount++;
                break;
            }
          }
        }

        final ohladenieAvg =
            ohladenieCount > 0 ? ohladenieTotal / ohladenieCount : 0.0;
        final zamorozkaAvg =
            zamorozkaCount > 0 ? zamorozkaTotal / zamorozkaCount : 0.0;
        final frovAvg = frovCount > 0 ? frovTotal / frovCount : 0.0;

        allSheetData.add(
          SheetData(
            date: sheet.title,
            ohladeniePercent: ohladenieAvg,
            zamorozkaPercent: zamorozkaAvg,
            frovPercent: frovAvg,
          ),
        );
      }

      final dateFormat = DateFormat('dd.MM.yyyy');
      allSheetData.sort((a, b) {
        try {
          DateTime dateA = dateFormat.parse(a.date);
          DateTime dateB = dateFormat.parse(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      return allSheetData;
    } catch (e) {
      print('Error fetching Google Sheets data: $e');
      rethrow;
    }
  }

  Future<List<ProductDetail>> fetchDetailsForSheet(String sheetTitle) async {
    try {
      final gsheets = GSheets(_credentials);
      final ss = await gsheets.spreadsheet(_spreadsheetId);
      final sheet = await ss.worksheetByTitle(sheetTitle);

      if (sheet == null) {
        throw Exception('Sheet with title "$sheetTitle" not found.');
      }

      final details = <ProductDetail>[];
      final values = await sheet.values.allRows(fromRow: 2);

      for (var row in values) {
        if (row.length > 11) {
          final code = row[2]; // Column C
          final name = row[3]; // Column D
          final category = row[4]; // Column E
          final percentageStr = row[11]; // Column L

          final percentage =
              double.tryParse(percentageStr.replaceAll(',', '.')) ?? 0.0;
          final cappedPercentage = percentage > 100.0 ? 100.0 : percentage;

          // Extract only numbers from the code
          final numericCode = code.replaceAll(RegExp(r'[^0-9]'), '');

          if (numericCode.isNotEmpty &&
              name.isNotEmpty &&
              category.isNotEmpty) {
            details.add(
              ProductDetail(
                code: numericCode,
                name: name,
                category: category.toUpperCase(),
                percentage: cappedPercentage,
              ),
            );
          }
        }
      }
      return details;
    } catch (e) {
      print('Error fetching details for sheet "$sheetTitle": $e');
      rethrow;
    }
  }
}
