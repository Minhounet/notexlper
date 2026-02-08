import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/presentation/models/display_mode.dart';

void main() {
  group('ChecklistDisplayMode', () {
    test('should have flat and groupedByCategory values', () {
      expect(ChecklistDisplayMode.values.length, 2);
      expect(ChecklistDisplayMode.values,
          contains(ChecklistDisplayMode.flat));
      expect(ChecklistDisplayMode.values,
          contains(ChecklistDisplayMode.groupedByCategory));
    });
  });
}
