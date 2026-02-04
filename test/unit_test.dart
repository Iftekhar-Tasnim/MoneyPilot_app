import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/services/preprocessing/text_preprocessor.dart';
import 'package:demo_app/services/rules/category_rules.dart';

void main() {
  group('TextPreprocessor Tests', () {
    test('Should normalize Bangla numbers correctly', () {
      expect(TextPreprocessor.instance.process('পাঁচশ টাকা'), contains('500 টাকা'));
      expect(TextPreprocessor.instance.process('দশ টাকা'), contains('10 টাকা'));
      expect(TextPreprocessor.instance.process('একশ পঞ্চাশ'), contains('100 50'));
    });

    test('Should remove fillers', () {
      expect(TextPreprocessor.instance.process('মানে পাঁচশ টাকা'), contains('500 টাকা'));
      expect(TextPreprocessor.instance.process('হ্যালো পাঁচশ'), contains('500'));
    });

    test('Should split clauses', () {
      final input = 'Market 500 and Bus 50';
      final clauses = TextPreprocessor.instance.process(input);
      expect(clauses.length, 2);
      expect(clauses[0], 'Market 500');
      expect(clauses[1], 'Bus 50');
    });

    test('Should handle complex Bangla sentence', () {
      final input = 'পাঁচশ টাকা বাজার এবং পঞ্চাশ টাকা রিকশা';
      final clauses = TextPreprocessor.instance.process(input);
      // 'পাঁচশ' -> 500, 'পঞ্চাশ' -> 50, 'এবং' -> split
      expect(clauses.length, 2);
      expect(clauses[0].trim(), '500 টাকা বাজার');
      expect(clauses[1].trim(), '50 টাকা রিকশা');
    });
  });

  group('CategoryRules Tests', () {
    test('Should detect Transport keywords', () {
      final tx = <String, dynamic>{'category': 'Other'};
      CategoryRules.apply(tx, 'Rickshaw 50');
      expect(tx['category'], 'Transport');

      CategoryRules.apply(tx, 'বাস ভাড়া 20');
      expect(tx['category'], 'Transport');
    });

    test('Should detect Groceries keywords', () {
      final tx = <String, dynamic>{'category': 'Other'};
      CategoryRules.apply(tx, 'Bazaar 500');
      expect(tx['category'], 'Groceries');

      CategoryRules.apply(tx, 'মাছ কিনলাম');
      expect(tx['category'], 'Groceries');
    });

    test('Should detect Bills keywords', () {
      final tx = <String, dynamic>{'category': 'Other'};
      CategoryRules.apply(tx, 'Electricity bill');
      expect(tx['category'], 'Bills');
      
      CategoryRules.apply(tx, 'Karrent bill');
      expect(tx['category'], 'Bills');
    });

    test('Should NOT override if no keyword found', () {
      final tx = <String, dynamic>{'category': 'Existing'};
      CategoryRules.apply(tx, 'Unknown thing');
      expect(tx['category'], 'Existing');
    });
  });
}
