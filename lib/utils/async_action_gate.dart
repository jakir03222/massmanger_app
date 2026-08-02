import 'package:flutter/foundation.dart';

/// Tracks in-flight ids so approve/reject buttons stay disabled once (DRY).
///
/// Usage in a [State]:
/// ```dart
/// final _gate = AsyncActionGate();
///
/// Future<void> _approve(String id) => _gate.run(id, () async { ... }, setState);
/// bool busy = _gate.isBusy(id);
/// ```
class AsyncActionGate {
  final Set<String> _busy = {};

  bool isBusy(String id) => _busy.contains(id);

  bool get hasBusy => _busy.isNotEmpty;

  Future<void> run(
    String id,
    Future<void> Function() action,
    void Function(VoidCallback fn) setState,
  ) async {
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await action();
    } finally {
      setState(() => _busy.remove(id));
    }
  }
}
