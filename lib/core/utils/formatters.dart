/// Small text helpers used by several screens.
String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes < 1 ? 1 : diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  return '${diff.inDays} days ago';
}

String money(double value) => '€${value.toStringAsFixed(2)}';

/// "2 L", "12 pcs", "1 pack"
String amount(int quantity, String unit) {
  if (unit == 'pcs' && quantity == 1) return '1 pc';
  return '$quantity $unit';
}

String plural(int count, String word) => '$count $word${count == 1 ? '' : 's'}';
