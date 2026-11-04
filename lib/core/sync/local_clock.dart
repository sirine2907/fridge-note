import 'dart:math' as math;

/// Hands out timestamps (ms) for local changes.
///
/// Phone clocks can be a little off. If this phone is behind and we just
/// received a change stamped "12:00:05", a toggle the user makes right after
/// must not be stamped "12:00:03", or it would lose against something it
/// clearly came after. So the clock never goes below the newest time it has
/// seen, and it never returns the same value twice.
class LocalClock {
  LocalClock({int Function()? now})
      : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final int Function() _now;
  int _last = 0;

  int next() {
    _last = math.max(_now(), _last + 1);
    return _last;
  }

  /// Call this with the time of every change that arrives from the server.
  void observe(int time) {
    if (time > _last) _last = time;
  }
}
