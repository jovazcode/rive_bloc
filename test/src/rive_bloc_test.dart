// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_bloc/rive_bloc.dart';

void main() {
  group('FinalProvider', () {
    test('can be instantiated', () {
      expect(RiveBlocProvider.finalValue(() => 0), isNotNull);
    });
  });
}
