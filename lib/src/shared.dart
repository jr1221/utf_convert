import 'util.dart';

/// Provide a list of Unicode codepoints for a given string.
List<int> stringToCodepoints(String str) {
  // Note: str.codeUnits gives us 16-bit code units on all Dart implementations.
  // So we need to convert.
  return utf16CodeUnitsToCodepoints(str.codeUnits);
}
