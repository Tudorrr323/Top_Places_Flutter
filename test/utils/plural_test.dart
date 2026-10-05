import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/utils/plural.dart';

void main() {
  test('resultsLabel follows the Romanian rule for "de"', () {
    expect(resultsLabel(0), '0 rezultate');
    expect(resultsLabel(1), '1 rezultat');
    expect(resultsLabel(3), '3 rezultate');
    expect(resultsLabel(19), '19 rezultate');
    expect(resultsLabel(20), '20 de rezultate');
    expect(resultsLabel(101), '101 rezultate');
  });

  test('countLabel works for any noun', () {
    expect(countLabel(1, 'recenzie', 'recenzii'), '1 recenzie');
    expect(countLabel(12, 'recenzie', 'recenzii'), '12 recenzii');
    expect(countLabel(100, 'recenzie', 'recenzii'), '100 de recenzii');
  });
}
