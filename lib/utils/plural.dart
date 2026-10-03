/// "1 rezultat", "3 rezultate", "20 de rezultate": Romanian adds "de" from 20
/// on, but not after 101-119, 201-219 and so on.
String resultsLabel(int count) {
  if (count == 1) return '1 rezultat';
  final lastTwoDigits = count % 100;
  final needsDe = count > 0 && (lastTwoDigits == 0 || lastTwoDigits >= 20);
  return needsDe ? '$count de rezultate' : '$count rezultate';
}