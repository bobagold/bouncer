/// Bouncer debounces actions
/// and makes sure any outdated answers will be ignored.
library bouncer;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Subscription provides Timer and StreamSubscription instances
/// that can be cancelled as soon as user input has been changed.
@immutable
class Subscription {
  /// timer that postpones any heavy request until some pause in user input
  final Timer timer;

  /// subscription to results of heavy request
  final Completer<StreamSubscription> subscription;

  /// constructor
  Subscription({
    @required this.timer,
    @required this.subscription,
  });

  /// cancels both timer and subscription to results
  void cancel() {
    if (timer.isActive) timer.cancel();
    if (subscription.isCompleted) {
      subscription.future.then((subscription) => subscription.cancel());
    }
  }
}

/// interface for different Bouncer implementations
@immutable
// ignore: one_member_abstracts
abstract class Bouncer {
  /// debounce user action from response handler and previous action
  Subscription debounce<T>({
    @required ValueGetter<Future<T>> request,
    @required ValueSetter<T> responseHandler,
    Subscription oldSubscription,
  });
}

/// no bouncing, just call requests on every input and handle response
@immutable
class NoBouncer extends Bouncer {
  @override
  Subscription debounce<T>({
    @required ValueGetter<Future<T>> request,
    @required ValueSetter<T> responseHandler,
    Subscription oldSubscription,
  }) {
    oldSubscription?.cancel();
    request().then(responseHandler);
    return null;
  }
}

/// Timer bouncer, waits for pause in user input and performs request
@immutable
class TimerBouncer extends Bouncer {
  /// delay in user input
  final Duration bounceDuration;

  /// takes [Duration] to determine pause in user input
  TimerBouncer(this.bounceDuration);

  @override
  Subscription debounce<T>({
    @required ValueGetter<Future<T>> request,
    @required ValueSetter<T> responseHandler,
    Subscription oldSubscription,
  }) {
    oldSubscription?.cancel();
    var subscriptionCompleter = Completer<StreamSubscription<T>>();
    return Subscription(
      timer: Timer(
        bounceDuration,
        () => subscriptionCompleter
            .complete(request().asStream().listen(responseHandler)),
      ),
      subscription: subscriptionCompleter,
    );
  }
}
