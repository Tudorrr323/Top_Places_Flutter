/// [count] with the right form of a Romanian noun: [one] for 1, [many]
/// otherwise, with "de" from 20 on ("20 de recenzii"), but not after
/// 101-119, 201-219 and so on.
String countLabel(int count, String one, String many) {
  if (count == 1) return '1 $one';
  final lastTwoDigits = count % 100;
  final needsDe = count > 0 && (lastTwoDigits == 0 || lastTwoDigits >= 20);
  return needsDe ? '$count de $many' : '$count $many';
}

/// "1 rezultat", "3 rezultate", "20 de rezultate".
String resultsLabel(int count) => countLabel(count, 'rezultat', 'rezultate');
