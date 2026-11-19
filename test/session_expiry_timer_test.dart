import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

String _token(DateTime expiry, {String subject = 'account-a'}) {
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({'sub': subject, 'exp': expiry.millisecondsSinceEpoch / 1000}),
    ),
  );
  return 'e30.$payload.test';
}

class _CapturedTimer implements Timer {
  _CapturedTimer(this.duration, this.callback);
  final Duration duration;
  final void Function() callback;
  @override
  bool isActive = true;
  @override
  int tick = 0;
  @override
  void cancel() => isActive = false;
  void fire() {
    isActive = false;
    tick++;
    callback();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  late List<_CapturedTimer> timers;

  void assignToken(String value) => runZoned(
    () => ApiService.token = value,
    zoneSpecification: ZoneSpecification(
      createTimer: (_, _, _, duration, callback) {
        final timer = _CapturedTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
    ),
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({'tv_score_session': 'fixture'});
    await ApiService().logout();
    timers = [];
  });
  tearDown(() => ApiService().logout());

  test(
    '30-day JWT uses a safe Web interval and reschedules without logout',
    () async {
      final token = _token(DateTime.now().add(const Duration(days: 30)));
      assignToken(token);
      await storage.write(key: 'tv_score_session', value: 'fixture');
      if (kIsWeb) {
        expect(timers.single.duration, const Duration(hours: 24));
      } else {
        expect(timers.single.duration, greaterThan(const Duration(days: 29)));
      }
      timers.single.fire();
      expect(ApiService.token, token);
      expect(timers, hasLength(2));
      expect(timers.where((timer) => timer.isActive), hasLength(1));
      if (kIsWeb) expect(timers.last.duration, const Duration(hours: 24));
      expect(await storage.read(key: 'tv_score_session'), 'fixture');
    },
  );

  test(
    'expired JWT schedules immediate cleanup of memory and storage',
    () async {
      assignToken(_token(DateTime.now().subtract(const Duration(seconds: 1))));
      await storage.write(key: 'tv_score_session', value: 'fixture');
      expect(ApiService.hasSession, isFalse);
      expect(timers.single.duration, Duration.zero);
      timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      expect(ApiService.token, isNull);
      expect(await storage.read(key: 'tv_score_session'), isNull);
      expect(timers.where((timer) => timer.isActive), isEmpty);
    },
  );

  test(
    'old timer cannot invalidate or reschedule over a replacement session',
    () async {
      assignToken(_token(DateTime.now().add(const Duration(days: 30))));
      final oldTimer = timers.single;
      final nextToken = _token(
        DateTime.now().add(const Duration(days: 7)),
        subject: 'account-b',
      );
      assignToken(nextToken);
      final nextTimer = timers.last;
      expect(oldTimer.isActive, isFalse);
      // Also cover a callback that was already queued when its timer was cancelled.
      oldTimer.fire();
      expect(ApiService.token, nextToken);
      expect(timers, hasLength(2));
      expect(nextTimer.isActive, isTrue);
      expect(timers.where((timer) => timer.isActive), hasLength(1));
      await ApiService().logout();
      nextTimer.fire();
      expect(ApiService.hasSession, isFalse);
      expect(timers, hasLength(2));
    },
  );
}
