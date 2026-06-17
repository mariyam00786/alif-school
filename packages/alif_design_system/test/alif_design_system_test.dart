import 'package:flutter_test/flutter_test.dart';

import 'package:alif_design_system/alif_design_system.dart';

void main() {
  test('exports theme tokens', () {
    expect(AlifColors.primary.toARGB32(), isNonZero);
    expect(AlifSpacing.screen.horizontal, greaterThan(0));
  });
}
