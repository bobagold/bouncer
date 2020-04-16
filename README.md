# bouncer

Bouncer debounces actions and makes sure any outdated answers will be ignored.

## Problem statement

When user actions lead to starting several concurrent requests to some slow resource,
there can be 2 problems:
1. exhausting of the resource
2. answers coming in random order

This library aims to solve both problems.

[<img src="examples/Screenshot1.gif" width="200" />](examples)

See [examples](examples) for reference.

## Usage

instead of 

```dart
  var response = await _longRunningRequest(parameters)
  _responseHandler(response);
```

let's debounce: 

```dart
  _debounceSubscription = TimerBouncer(Duration(milliseconds: 200)).debounce(
    request: () => _longRunningRequest(parameters),
    responseHandler: _responseHandler,
    oldSubscription: _debounceSubscription,
  );
```

don't forget to dispose _debounceSubscription when it's no longer in use.

```dart
  @override
  dispose() {
    _debounceSubscription?.cancel();
    super.dispose();
  }
```
