import 'dart:math';

import 'package:bouncer/bouncer.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Bouncer example',
      home: MyHomePage(),
    ),
  );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _result = 'No results so far';
  bool _bouncerIsOn = false;
  Subscription _debounceSubscription;

  // for example, get the configured bouncer from context
  // default - no bouncing, good for tests ans such
  Bouncer _bouncer(BuildContext context) {
    if (_bouncerIsOn) {
      return TimerBouncer(Duration(milliseconds: 200));
    } else {
      return NoBouncer();
    }
  }

  void _searchTextChanged(BuildContext context, String search) {
    // NoBouncer effectively does the same as
    // _responseHandler(await _longRunningRequest(search))
    _debounceSubscription = _bouncer(context).debounce(
      request: () => _longRunningRequest(search),
      responseHandler: _responseHandler,
      oldSubscription: _debounceSubscription,
    );
  }

  // this request execution time depends on length of search string
  // to simulate race conditions
  Future<String> _longRunningRequest(String search) {
    var rand = Random();
    return Future.delayed(
      Duration(seconds: rand.nextInt(2)),
      () => search.toUpperCase(),
    );
  }

  void _responseHandler(String result) {
    setState(() {
      _result = result;
    });
  }

  void _toggleBouncer(bool value) {
    setState(() {
      _bouncerIsOn = value;
    });
  }

  /// dispose our subscription so they cannot call setState
  @override
  dispose() {
    _debounceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bouncer example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: Text('Turn on the bouncer'),
            leading: Switch(
              value: _bouncerIsOn,
              onChanged: _toggleBouncer,
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter a search term',
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => _searchTextChanged(context, value),
          ),
          ListTile(title: Text('Result: $_result'))
        ],
      ),
    );
  }
}
