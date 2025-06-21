import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final autoLockState = Provider.of<AutoLockState>(context, listen: false);

    if (!autoLockState.isAutoLockEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      //Start timer
      _lockTimer?.cancel();
      if (autoLockState.lockDuration == 0) {
        widget.onAutoLock();
      } else {
        _lockTimer = Timer(Duration(seconds: autoLockState.lockDuration), () {
          widget.onAutoLock();
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
