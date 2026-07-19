import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/services/app_version_service.dart';

void main() {
  group('AppVersionService', () {
    test('compareVersions correctly compares versions', () {
      expect(AppVersionService.compareVersions('1.0.0', '1.0.0'), 0);
      expect(AppVersionService.compareVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(AppVersionService.compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(AppVersionService.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(AppVersionService.compareVersions('1.9.9', '2.0.0'), lessThan(0));
      expect(AppVersionService.compareVersions('1.10.0', '1.2.0'), greaterThan(0));
    });

    test('compareVersions handles shorter versions', () {
      expect(AppVersionService.compareVersions('1.0', '1.0.0'), 0);
      expect(AppVersionService.compareVersions('1', '1.0.0'), 0);
      expect(AppVersionService.compareVersions('1.1', '1.0.0'), greaterThan(0));
    });
  });
}
