import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'autolock_state.dart';

class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  final VoidCallback onAutoLock;

  const LifecycleWatcher({
    Key? key,
    required this.child,
    required this.onAutoLock,
  }) : super(key: key);

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher> with WidgetsBindingObserver {
  Timer? _lockTimer;
  DateTime? _lastPausedTime;
  bool _screenOff = false;
  final MethodChannel _channel = const MethodChannel('com.ilhanidriss.wan_protector/screen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'screenOff':
        _handleScreenOff();
        break;
      case 'screenOn':
        _handleScreenOn();
        break;
    }
  }

  void _handleScreenOff() {
    if (!mounted) return;
    final autoLockState = Provider.of<AutoLockState>(context, listen: false);
    if (!autoLockState.isAutoLockEnabled) return;
    
    _screenOff = true;
    _startLockTimer(autoLockState.lockDuration);
  }

  void _handleScreenOn() {
    if (!mounted) return;
    _screenOff = false;
    // Additional logic if needed when screen turns on
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final autoLockState = Provider.of<AutoLockState>(context, listen: false);

    if (!autoLockState.isAutoLockEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _lastPausedTime = DateTime.now();
      _startLockTimer(autoLockState.lockDuration);
    } 
    else if (state == AppLifecycleState.resumed) {
      _screenOff = false;
      _lockTimer?.cancel();
      
      if (_lastPausedTime != null) {
        final elapsed = DateTime.now().difference(_lastPausedTime!);
        if (elapsed.inSeconds >= autoLockState.lockDuration) {
          widget.onAutoLock();
        }
      }
    }
  }

  void _startLockTimer(int duration) {
    _lockTimer?.cancel();
    
    if (duration == 0) {
      widget.onAutoLock();
    } else {
      _lockTimer = Timer(Duration(seconds: duration), () {
        if (mounted && (_screenOff || _lastPausedTime != null)) {
          widget.onAutoLock();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}