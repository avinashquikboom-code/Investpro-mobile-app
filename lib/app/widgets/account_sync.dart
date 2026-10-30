import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_diagnostics.dart';

/// Silent authenticated polling: one request at a time, paused in the background.
class AccountSync extends StatefulWidget {
  final Widget child;
  final bool authenticated;
  final Future<void> Function() refresh;
  final DateTime? Function()? nextRetryAt;
  final Duration interval;
  final bool initialRefresh;
  const AccountSync({
    super.key,
    required this.child,
    required this.authenticated,
    required this.refresh,
    this.nextRetryAt,
    this.interval = const Duration(seconds: 60),
    this.initialRefresh = true,
  });
  @override
  State<AccountSync> createState() => _AccountSyncState();
}

class _AccountSyncState extends State<AccountSync> with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false, _active = true;
  int _failures = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule(immediate: widget.initialRefresh);
  }

  void _schedule({bool immediate = false}) {
    _timer?.cancel();
    if (!mounted || !widget.authenticated || !_active) return;
    final now = DateTime.now(), retry = widget.nextRetryAt?.call();
    var delay = immediate
        ? Duration.zero
        : Duration(
            seconds: (widget.interval.inSeconds * (1 << _failures)).clamp(
              1,
              300,
            ),
          );
    if (retry != null && retry.isAfter(now) && retry.difference(now) > delay) {
      delay = retry.difference(now);
    }
    if (delay == Duration.zero) {
      unawaited(_refresh());
    } else {
      _timer = Timer(delay, () => unawaited(_refresh()));
    }
  }

  Future<void> _refresh() async {
    if (_busy || !mounted || !widget.authenticated || !_active) return;
    final retry = widget.nextRetryAt?.call();
    if (retry != null && retry.isAfter(DateTime.now())) {
      _schedule();
      return;
    }
    _busy = true;
    try {
      await widget.refresh();
      _failures = 0;
    } catch (error) {
      _failures = (_failures + 1).clamp(0, 3);
      ApiDiagnostics.log(error);
    } finally {
      _busy = false;
      _schedule();
    }
  }

  @override
  void didUpdateWidget(covariant AccountSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authenticated != widget.authenticated) {
      _failures = 0;
      _schedule(immediate: widget.initialRefresh);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _schedule(immediate: _active);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
