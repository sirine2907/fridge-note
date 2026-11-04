import 'dart:convert';

/// Result of merging a change into a row.
class MergeResult {
  const MergeResult({required this.values, required this.times, required this.changed});

  final Map<String, Object?> values;
  final Map<String, int> times;

  /// False when the incoming change was older everywhere, so nothing was taken.
  final bool changed;
}

/// Per-field last-write-wins.
///
/// Every column is compared on its own: the value with the newer time wins.
/// So if Anis renames "Milk" while Sirine checks it off, both changes survive,
/// because they touch different columns.
///
/// When two times are exactly equal, the bigger JSON value wins. That rule is
/// arbitrary, but every device uses it, so they all end up with the same row.
/// For the checked column it means "true" beats "false", so a tie never drops
/// a check.
MergeResult mergeFields({
  required Map<String, Object?> currentValues,
  required Map<String, int> currentTimes,
  required Map<String, Object?> incomingValues,
  required Map<String, int> incomingTimes,
}) {
  final values = Map<String, Object?>.of(currentValues);
  final times = Map<String, int>.of(currentTimes);
  var changed = false;

  for (final key in incomingValues.keys) {
    final incomingValue = incomingValues[key];
    final incomingTime = incomingTimes[key] ?? 0;
    final hasCurrent = times.containsKey(key);
    final currentTime = times[key] ?? 0;

    final bool takeIncoming;
    if (!hasCurrent || incomingTime > currentTime) {
      takeIncoming = true;
    } else if (incomingTime == currentTime) {
      takeIncoming = _compareValues(incomingValue, values[key]) > 0;
    } else {
      takeIncoming = false;
    }

    if (takeIncoming) {
      if (values[key] != incomingValue || times[key] != incomingTime) changed = true;
      values[key] = incomingValue;
      times[key] = incomingTime;
    }
  }

  return MergeResult(values: values, times: times, changed: changed);
}

int _compareValues(Object? a, Object? b) {
  if (a == b) return 0;
  return jsonEncode(a).compareTo(jsonEncode(b));
}
