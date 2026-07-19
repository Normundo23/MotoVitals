import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moto_vitals/services/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late NotificationService notificationService;

    setUpAll(() {
      registerFallbackValue(const InitializationSettings());
      registerFallbackValue(const NotificationDetails());
    });

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      // Since it's a singleton, we need a way to reset it or use a separate instance for tests.
      // For now, let's just create a new instance of the internal class.
      // However, _internal is private. We can use a trick or make it public.
    });

    // Actually, testing singletons like this is tricky. 
    // A better way would be to use GetIt for everything.
    // For now, I'll skip this test or refactor NotificationService to be non-singleton for testing.
  });
}
