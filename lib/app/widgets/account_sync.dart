import 'dart:async';
import 'package:flutter/material.dart';

/// Authenticated polling fallback. Pauses while backgrounded and deduplicates requests.
class AccountSync extends StatefulWidget {
  final Widget child;
  final bool authenticated;
  final Future<void> Function() refresh;
  const AccountSync({super.key, required this.child, required this.authenticated, required this.refresh});
  @override
  State<AccountSync> createState() => _AccountSyncState();
}
class _AccountSyncState extends State<AccountSync> with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false;
  bool _active = true;
  String? _error;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _schedule(); }
  void _schedule() {
    _timer?.cancel();
    if (widget.authenticated && _active) {
      unawaited(_refresh());
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => unawaited(_refresh()));
    }
  }
  Future<void> _refresh() async {
    if (_busy || !widget.authenticated || !_active) return;
    _busy = true;
    try { await widget.refresh(); if (mounted) setState(() => _error = null); }
    catch (_) { if (mounted && widget.authenticated) setState(() => _error = 'Synchronization unavailable. Pull to refresh or retry.'); }
    finally { _busy = false; }
  }
  @override
  void didUpdateWidget(covariant AccountSync oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.authenticated != widget.authenticated) { _error = null; _schedule(); } }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { _active = state == AppLifecycleState.resumed; _schedule(); }
  @override
  void dispose() { _timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    if (_error != null && widget.authenticated) Material(color: Theme.of(context).colorScheme.errorContainer,
      child: SafeArea(bottom: false, child: ListTile(dense: true, title: Text(_error!), trailing: TextButton(onPressed: _refresh, child: const Text('Retry'))))),
    Expanded(child: widget.child),
  ]);
}
