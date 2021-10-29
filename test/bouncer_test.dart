import 'dart:async';

import 'package:bouncer/bouncer.dart';
import 'package:test/test.dart';

void main() {
  Future<int> fastRequest() => Future.value(3);
  Future<int> slowRequest() => Future.delayed(Duration(seconds: 3), () => 3);

  test('NoBouncer lets everyone in', () {
    final bouncer = NoBouncer();
    var completer = Completer();
    var subscription = bouncer.debounce(
      request: fastRequest,
      responseHandler: completer.complete,
    );
    expect(subscription, null);
    expect(completer.future, completion(equals(3)));
  });

  group('TimerBouncer', () {
    test('it lets everyone in', () {
      final bouncer = TimerBouncer(Duration.zero);
      var completer = Completer();
      var subscription = bouncer.debounce(
        request: fastRequest,
        responseHandler: completer.complete,
      );
      expect(subscription, isA<Subscription>());
      expect(completer.future, completes);
    });
    test('double cancel makes no harm', () {
      final bouncer = TimerBouncer(Duration.zero);
      var completer = Completer();
      var subscription = bouncer.debounce(
        request: fastRequest,
        responseHandler: completer.complete,
      );
      subscription.cancel();
      subscription.cancel();
    });
    test('it allows to cancel responseHandler', () {
      final bouncer = TimerBouncer(Duration.zero);
      var completer = Completer();
      var subscription = bouncer.debounce(
        request: slowRequest,
        responseHandler: completer.complete,
      );
      subscription.cancel();
      expect(completer.future, doesNotComplete);
    });
    test('it actually postpones request', () {
      final bouncer = TimerBouncer(Duration(seconds: 3));
      var completer1 = Completer();
      var completer2 = Completer();
      Future<int> fastRequestThatWillNotRun() {
        completer1.complete();
        return Future.value(3);
      }

      var subscription = bouncer.debounce(
        request: fastRequestThatWillNotRun,
        responseHandler: completer2.complete,
      );
      expect(completer1.future, doesNotComplete);
      expect(completer2.future, doesNotComplete);
      subscription.cancel();
    });
    test('it cancels previous subscription', () {
      final bouncer = TimerBouncer(Duration.zero);
      var completer1 = Completer();
      var completer2 = Completer();
      var subscription = bouncer.debounce(
        request: slowRequest,
        responseHandler: completer1.complete,
      );
      bouncer.debounce(
        request: slowRequest,
        responseHandler: completer2.complete,
        oldSubscription: subscription,
      );
      expect(completer1.future, doesNotComplete);
      expect(completer2.future, completes);
    });
  });
}
