import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/utils/clusters.dart';

void main() {
  const positions = {
    'a': Offset(0, 0),
    'b': Offset(30, 0),
    'c': Offset(0, 40),
    'd': Offset(300, 300),
  };

  List<List<String>> group(List<String> items, {double distance = 48}) =>
      groupNearby(items, (item) => positions[item]!, distance: distance);

  test('items closer than the distance share a group', () {
    expect(group(['a', 'b', 'c', 'd']), [
      ['a', 'b', 'c'],
      ['d'],
    ]);
  });

  test('items far apart keep a group each', () {
    expect(group(['a', 'b', 'd'], distance: 10), [
      ['a'],
      ['b'],
      ['d'],
    ]);
  });

  test('a group is measured from its first item, not in a chain', () {
    // b is 30 from a and c is 50 from b, but 80 from a.
    const chain = {'a': Offset(0, 0), 'b': Offset(30, 0), 'c': Offset(80, 0)};
    expect(groupNearby(['a', 'b', 'c'], (item) => chain[item]!, distance: 48), [
      ['a', 'b'],
      ['c'],
    ]);
  });

  test('no items, no groups', () {
    expect(group([]), isEmpty);
  });
}
