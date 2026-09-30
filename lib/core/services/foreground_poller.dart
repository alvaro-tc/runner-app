import 'dart:async';

import 'package:flutter/widgets.dart';

/// Polls only while the app is visible. Resuming refreshes immediately.
class ForegroundPoller {
  ForegroundPoller({required this.interval, required this.onPoll}) {
    _lifecycle = AppLifecycleListener(onStateChange: _onStateChange);
    _active = true;
    _onStateChange(WidgetsBinding.instance.lifecycleState);
  }

  final Duration interval;
  final VoidCallback onPoll;
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  bool _active = false;

  void _onStateChange(AppLifecycleState? state) {
    final active = state == null || state == AppLifecycleState.resumed;
    _timer?.cancel();
    if (active) {
      _timer = Timer.periodic(interval, (_) => onPoll());
      if (!_active && state != null) onPoll();
    }
    _active = active;
  }

  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
  }
}
