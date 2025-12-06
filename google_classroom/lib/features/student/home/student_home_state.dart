// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Id của học kỳ đang chọn (int?)
final selectedSemesterIdProvider = StateProvider<int?>((ref) => null);

/// Code của học kỳ đang chọn (String?)
final selectedSemesterCodeProvider = StateProvider<String?>((ref) => null);
