import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/services/data_export_service.dart';

void main() {
  group('DataExportService', () {
    test('formatFileSize correctly formats bytes', () {
      expect(DataExportService.formatFileSize(500), '500 B');
      expect(DataExportService.formatFileSize(1024), '1.0 KB');
      expect(DataExportService.formatFileSize(1536), '1.5 KB');
      expect(DataExportService.formatFileSize(1048576), '1.0 MB');
      expect(DataExportService.formatFileSize(2097152), '2.0 MB');
    });
  });
}
