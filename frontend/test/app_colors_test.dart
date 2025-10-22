import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/log_in.dart'; // This imports AppColors

void main() {
  group('AppColors Tests', () {
    test('AppColors has correct primary blue color', () {
      expect(AppColors.primaryBlue, const Color(0xFFDD886C));
    });

    test('AppColors has correct link blue color', () {
      expect(AppColors.linkBlue, const Color(0xFFC96E6E));
    });

    test('AppColors has correct field fill color', () {
      expect(AppColors.fieldFill, const Color(0xFFF1F3F6));
    });

    test('AppColors has correct background color', () {
      expect(AppColors.background, const Color(0xFFFFFDE2));
    });

    test('AppColors colors are not null', () {
      expect(AppColors.primaryBlue, isNotNull);
      expect(AppColors.linkBlue, isNotNull);
      expect(AppColors.fieldFill, isNotNull);
      expect(AppColors.background, isNotNull);
    });

    test('AppColors colors are Color objects', () {
      expect(AppColors.primaryBlue, isA<Color>());
      expect(AppColors.linkBlue, isA<Color>());
      expect(AppColors.fieldFill, isA<Color>());
      expect(AppColors.background, isA<Color>());
    });
  });
}
