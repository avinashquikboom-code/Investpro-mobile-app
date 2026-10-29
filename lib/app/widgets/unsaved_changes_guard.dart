import 'dart:async';
import 'package:flutter/material.dart';

/// Discard policy shared by toolbar back and Android system back.
/// Clean forms retain native swipe-back. Dirty forms disable iOS swipe-back;
/// the toolbar provides the same confirmation without accidental data loss.
class UnsavedChangesGuard extends StatefulWidget {
  final Widget child;
  final List<TextEditingController> controllers;
  final List<Stream<dynamic>> changes;
  final Object? Function()? snapshot;
  const UnsavedChangesGuard({super.key, required this.child,
    this.controllers = const [], this.changes = const [], this.snapshot});
  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  late List<String> _initialText;
  Object? _initialExtra;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _allowPop = false;
  bool _asking = false;
  bool _dirty = false;
  @override
  void initState() {
    super.initState();
    _initialText = widget.controllers.map((c) => c.text).toList();
    _initialExtra = widget.snapshot?.call();
    for (final controller in widget.controllers) { controller.addListener(_changed); }
    for (final stream in widget.changes) { _subscriptions.add(stream.listen((_) => _changed())); }
  }
  bool get _hasChanges {
    for (var i = 0; i < widget.controllers.length; i++) {
      if (i >= _initialText.length || widget.controllers[i].text != _initialText[i]) return true;
    }
    return widget.snapshot?.call() != _initialExtra;
  }
  void _changed() {
    if (mounted && _dirty != _hasChanges) { setState(() => _dirty = _hasChanges); }
  }
  @override
  void didUpdateWidget(UnsavedChangesGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final controller in oldWidget.controllers) { controller.removeListener(_changed); }
    for (final controller in widget.controllers) { controller.addListener(_changed); }
    _dirty = _hasChanges;
  }
  @override
  void dispose() {
    for (final controller in widget.controllers) { controller.removeListener(_changed); }
    for (final subscription in _subscriptions) { subscription.cancel(); }
    super.dispose();
  }
  Future<void> _confirm(Object? result) async {
    if (_asking || !mounted) return;
    _asking = true;
    final navigator = Navigator.of(context);
    final discard = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text('Your unsaved changes will be lost.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Editing')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard'))]));
    _asking = false;
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && navigator.canPop()) { navigator.pop(result); }
    }
  }
  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allowPop || !_dirty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _dirty) { _confirm(result); }
    }, child: widget.child);
}
