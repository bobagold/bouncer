library bouncer;

import 'dart:async';

import 'package:flutter/widgets.dart';

@immutable
class Subscription {
  final Timer timer;
  final Completer<StreamSubscription> subscription;

  Subscription({
    @required this.timer,
    @required this.subscription,
  });

  void cancel() {
    if (timer.isActive) timer.cancel();
    if (subscription.isCompleted) {
      subscription.future.then((subscription) => subscription.cancel());
    }
  }
}

@immutable
abstract class Bouncer {
  Subscription debounce<T>({
    @required ValueGetter<Future<T>> request,
    @required ValueSetter<T> responseHandler,
    Subscription oldSubscription,
  });
}

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

@immutable
class TimerBouncer extends Bouncer {
  final Duration bounceDuration;

  TimerBouncer(this.bounceDuration);

  @override
  Subscription debounce<T>({
    @required ValueGetter<Future<T>> request,
    @required ValueSetter<T> responseHandler,
    Subscription oldSubscription,
  }) {
    oldSubscription?.cancel();
    Completer<StreamSubscription<T>> subscriptionCompleter = Completer();
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
