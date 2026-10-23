import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/services/deep_link_service.dart';
import 'package:campus_navigator/data/mock_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkService Unit & Integration Tests', () {
    final List<MethodCall> channelCalls = [];

    setUp(() {
      channelCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          channelCalls.add(methodCall);
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': 'https://campusconnect.amrita.edu/event?id=e1'};
          }
          return null;
        },
      );
    });

    test('Parses HTTPS deep link URL and copies link to clipboard', () async {
      final service = DeepLinkService.instance;
      const testLink = 'https://campusconnect.amrita.edu/event?id=e1';

      final result = await service.handleLink(testLink);

      // Verify event was resolved
      expect(result, isTrue);

      // Verify Clipboard.setData was called with the shareable link
      final clipboardCalls = channelCalls.where((c) => c.method == 'Clipboard.setData').toList();
      expect(clipboardCalls.isNotEmpty, isTrue);
      final dynamic arguments = clipboardCalls.first.arguments;
      expect(arguments['text'], equals('https://campusconnect.amrita.edu/event?id=e1'));
    });

    test('Parses custom scheme campusconnect://event?id=e1 and copies link', () async {
      final service = DeepLinkService.instance;
      const testLink = 'campusconnect://event?id=e1';

      final result = await service.handleLink(testLink);

      expect(result, isTrue);
      final clipboardCalls = channelCalls.where((c) => c.method == 'Clipboard.setData').toList();
      expect(clipboardCalls.isNotEmpty, isTrue);
      expect(clipboardCalls.last.arguments['text'], equals('https://campusconnect.amrita.edu/event?id=e1'));
    });

    test('Parses direct path format https://campusconnect.amrita.edu/event/e1', () async {
      final service = DeepLinkService.instance;
      const testLink = 'https://campusconnect.amrita.edu/event/e1';

      final result = await service.handleLink(testLink);

      expect(result, isTrue);
      final clipboardCalls = channelCalls.where((c) => c.method == 'Clipboard.setData').toList();
      expect(clipboardCalls.isNotEmpty, isTrue);
      expect(clipboardCalls.last.arguments['text'], equals('https://campusconnect.amrita.edu/event?id=e1'));
    });

    test('Title matching fallback when id is title keyword', () async {
      final service = DeepLinkService.instance;
      final existingTitle = MockData.events.first.title;

      final result = await service.handleLink(existingTitle);

      expect(result, isTrue);
    });

    test('Parses deep link with rich query parameters for unauthenticated guests', () async {
      final service = DeepLinkService.instance;
      const testLink = 'https://campusconnect.amrita.edu/event?id=robotics_expo_99&title=Robotics+Expo+2026&loc=Tech+Park+Hall+A&cat=Technology&org=Robotics+Club';

      final result = await service.handleLink(testLink);

      expect(result, isTrue);
      expect(service.pendingEvent, isNotNull);
      expect(service.pendingEvent!.title, equals('Robotics Expo 2026'));
      expect(service.pendingEvent!.location, equals('Tech Park Hall A'));
      expect(service.pendingEvent!.category, equals('Technology'));
      expect(service.pendingEvent!.organizer, equals('Robotics Club'));

      final clipboardCalls = channelCalls.where((c) => c.method == 'Clipboard.setData').toList();
      expect(clipboardCalls.isNotEmpty, isTrue);
      expect(clipboardCalls.last.arguments['text'], equals(testLink));
    });
  });
}
