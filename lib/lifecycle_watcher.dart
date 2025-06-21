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

  static _LifecycleWatcherState? of (BuildContext context) {
    final state = context.findAncestorStateOfType<_LifecycleWatcherState>();
    return state;
  }

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher> with WidgetsBindingObserver {
  Timer? _lockTimer;
  bool _screenOff = false;
  bool _isOperationInProgress = false;
  bool _isAppBackgrounded = false;
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
    if (!autoLockState.isAutoLockEnabled || _isOperationInProgress) return;

    _screenOff = true;
    _startLockTimer(autoLockState.lockDuration);
  }

  void _handleScreenOn() {
    if (!mounted) return;
    _screenOff = false;
    _lockTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final autoLockState = Provider.of<AutoLockState>(context, listen: false);
    if (!autoLockState.isAutoLockEnabled || _isOperationInProgress) return;

    _isAppBackgrounded = state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    
    if (_isAppBackgrounded) {
      _startLockTimer(autoLockState.lockDuration);
    } else {
      _lockTimer?.cancel();
    }
  }

  void _startLockTimer(int duration) {
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(seconds: duration), () {
      if (mounted && !_isOperationInProgress && (_screenOff || _isAppBackgrounded)) {
        widget.onAutoLock();
      }
    });
  }

  void pauseAutoLock() {
    if (!mounted) return;
    _isOperationInProgress = true;
    _lockTimer?.cancel();
  }

  void resumeAutoLock(int duration) {
    if (!mounted) return;
    _isOperationInProgress = false;
    _lockTimer?.cancel();
    if (duration > 0) {
      _startLockTimer(duration);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
