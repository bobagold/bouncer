import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bouncer/bouncer.dart';

void main() {
  var fastRequest = () => Future.value(3);
  var slowRequest = () => Future.delayed(Duration(seconds: 3), () => 3);

  test('NoBouncer lets everyone', () {
    final bouncer = NoBouncer();
    var completer = Completer();
    var subscription = bouncer.debounce(
      request: fastRequest,
      responseHandler: completer.complete,
    );
    expect(subscription, null);
    expect(completer.future, completion(equals(3)));
  });
  test('TimerBouncer lets everyone', () {
    final bouncer = TimerBouncer(Duration.zero);
    var completer = Completer();
    var subscription = bouncer.debounce(
      request: fastRequest,
      responseHandler: completer.complete,
    );
    expect(subscription, isInstanceOf<Subscription>());
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
  test('TimerBouncer allows to cancel responseHandler', () {
    final bouncer = TimerBouncer(Duration.zero);
    var completer = Completer();
    var subscription = bouncer.debounce(
      request: slowRequest,
      responseHandler: completer.complete,
    );
    subscription.cancel();
    expect(completer.future, doesNotComplete);
  });
  test('TimerBouncer actually postpones request', () {
    final bouncer = TimerBouncer(Duration(seconds: 3));
    var completer1 = Completer();
    var completer2 = Completer();
    var fastRequestThatWillNotRun = () {
      completer1.complete();
      return Future.value(3);
    };
    var subscription = bouncer.debounce(
      request: fastRequestThatWillNotRun,
      responseHandler: completer2.complete,
    );
    expect(completer1.future, doesNotComplete);
    expect(completer2.future, doesNotComplete);
    subscription.cancel();
  });
  test('TimerBouncer cancels previous subscription', () {
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
}
