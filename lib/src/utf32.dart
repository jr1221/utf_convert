library utf_convert.utf32;

import 'dart:collection';

import 'constants.dart';
import 'list_range.dart';
import 'shared.dart';

/// Decodes the UTF-32 bytes as an iterable. Thus, the consumer can only convert
/// as much of the input as needed. Determines the byte order from the BOM,
/// or uses big-endian as a default. This method always strips a leading BOM.
/// Set the replacementCharacter to null to throw an ArgumentError
/// rather than replace the bad value.
IterableUtf32Decoder decodeUtf32AsIterable(List<int> bytes,
    [int offset = 0,
    int? length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return IterableUtf32Decoder._(
      () => Utf32BytesDecoder(bytes, offset, length, replacementCodepoint));
}

/// Decodes the UTF-32BE bytes as an iterable. Thus, the consumer can only convert
/// as much of the input as needed. This method strips a leading BOM by default,
/// but can be overridden by setting the optional parameter [stripBom] to false.
/// Set the replacementCharacter to null to throw an ArgumentError
/// rather than replace the bad value.
IterableUtf32Decoder decodeUtf32beAsIterable(List<int> bytes,
    [int offset = 0,
    int? length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return IterableUtf32Decoder._(() => Utf32beBytesDecoder(
      bytes, offset, length, stripBom, replacementCodepoint));
}

/// Decodes the UTF-32LE bytes as an iterable. Thus, the consumer can only convert
/// as much of the input as needed. This method strips a leading BOM by default,
/// but can be overridden by setting the optional parameter [stripBom] to false.
/// Set the replacementCharacter to null to throw an ArgumentError
/// rather than replace the bad value.
IterableUtf32Decoder decodeUtf32leAsIterable(List<int> bytes,
    [int offset = 0,
    int? length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return IterableUtf32Decoder._(() => Utf32leBytesDecoder(
      bytes, offset, length, stripBom, replacementCodepoint));
}

/// Produce a String from a sequence of UTF-32 encoded bytes. The parameters
/// allow an offset into a list of bytes (as int), limiting the length of the
/// values be decoded and the ability of override the default Unicode
/// replacement character. Set the replacementCharacter to null to throw an
/// ArgumentError rather than replace the bad value.
String decodeUtf32(List<int> bytes,
    [int offset = 0,
    int? length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return String.fromCharCodes(
      (Utf32BytesDecoder(bytes, offset, length, replacementCodepoint))
          .decodeRest());
}

/// Produce a String from a sequence of UTF-32BE encoded bytes. The parameters
/// allow an offset into a list of bytes (as int), limiting the length of the
/// values be decoded and the ability of override the default Unicode
/// replacement character. Set the replacementCharacter to null to throw an
/// ArgumentError rather than replace the bad value.
String decodeUtf32be(List<int> bytes,
        [int offset = 0,
        int? length,
        bool stripBom = true,
        int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
    String.fromCharCodes((Utf32beBytesDecoder(
            bytes, offset, length, stripBom, replacementCodepoint))
        .decodeRest());

/// Produce a String from a sequence of UTF-32LE encoded bytes. The parameters
/// allow an offset into a list of bytes (as int), limiting the length of the
/// values be decoded and the ability of override the default Unicode
/// replacement character. Set the replacementCharacter to null to throw an
/// ArgumentError rather than replace the bad value.
String decodeUtf32le(List<int> bytes,
        [int offset = 0,
        int? length,
        bool stripBom = true,
        int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
    String.fromCharCodes((Utf32leBytesDecoder(
            bytes, offset, length, stripBom, replacementCodepoint))
        .decodeRest());

/// Produce a list of UTF-32 encoded bytes. This method prefixes the resulting
/// bytes with a big-endian byte-order-marker.
List<int> encodeUtf32(String str) => encodeUtf32be(str, true);

/// Produce a list of UTF-32BE encoded bytes. By default, this method produces
/// UTF-32BE bytes with no BOM.
List<int> encodeUtf32be(String str, [bool writeBOM = false]) {
  var utf32CodeUnits = stringToCodepoints(str);
  var encoding = List<int>.filled((4 * utf32CodeUnits.length + (writeBOM ? 4 : 0)), -1);
  var i = 0;
  if (writeBOM) {
    encoding[i++] = 0;
    encoding[i++] = 0;
    encoding[i++] = UNICODE_UTF_BOM_HI;
    encoding[i++] = UNICODE_UTF_BOM_LO;
  }
  for (var unit in utf32CodeUnits) {
    encoding[i++] = (unit >> 24) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 16) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 8) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
  }
  return encoding;
}

/// Produce a list of UTF-32LE encoded bytes. By default, this method produces
/// UTF-32BE bytes with no BOM.
List<int> encodeUtf32le(String str, [bool writeBOM = false]) {
  var utf32CodeUnits = stringToCodepoints(str);
  var encoding = List<int>.filled((4 * utf32CodeUnits.length + (writeBOM ? 4 : 0)), -1);
  var i = 0;
  if (writeBOM) {
    encoding[i++] = UNICODE_UTF_BOM_LO;
    encoding[i++] = UNICODE_UTF_BOM_HI;
    encoding[i++] = 0;
    encoding[i++] = 0;
  }
  for (var unit in utf32CodeUnits) {
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 8) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 16) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 24) & UNICODE_BYTE_ZERO_MASK;
  }
  return encoding;
}

/// Identifies whether a List of bytes starts (based on offset) with a
/// byte-order marker (BOM).
bool hasUtf32Bom(List<int> utf32EncodedBytes, [int offset = 0, int? length]) {
  return hasUtf32beBom(utf32EncodedBytes, offset, length) ||
      hasUtf32leBom(utf32EncodedBytes, offset, length);
}

/// Identifies whether a List of bytes starts (based on offset) with a
/// big-endian byte-order marker (BOM).
bool hasUtf32beBom(List<int> utf32EncodedBytes, [int offset = 0, int? length]) {
  var end = length != null ? offset + length : utf32EncodedBytes.length;
  return (offset + 4) <= end &&
      utf32EncodedBytes[offset] == 0 &&
      utf32EncodedBytes[offset + 1] == 0 &&
      utf32EncodedBytes[offset + 2] == UNICODE_UTF_BOM_HI &&
      utf32EncodedBytes[offset + 3] == UNICODE_UTF_BOM_LO;
}

/// Identifies whether a List of bytes starts (based on offset) with a
/// little-endian byte-order marker (BOM).
bool hasUtf32leBom(List<int> utf32EncodedBytes, [int offset = 0, int? length]) {
  var end = length != null ? offset + length : utf32EncodedBytes.length;
  return (offset + 4) <= end &&
      utf32EncodedBytes[offset] == UNICODE_UTF_BOM_LO &&
      utf32EncodedBytes[offset + 1] == UNICODE_UTF_BOM_HI &&
      utf32EncodedBytes[offset + 2] == 0 &&
      utf32EncodedBytes[offset + 3] == 0;
}

typedef Utf32BytesDecoderProvider = Utf32BytesDecoder Function();

/// Return type of [decodeUtf32AsIterable] and variants. The Iterable type
/// provides an iterator on demand and the iterator will only translate bytes
/// as requested by the user of the iterator. (Note: results are not cached.)

class IterableUtf32Decoder extends IterableBase<int> {
  final Utf32BytesDecoderProvider codeunitsProvider;

  IterableUtf32Decoder._(this.codeunitsProvider);

  @override
  Utf32BytesDecoder get iterator => codeunitsProvider();
}

/// Abstract parent class converts encoded bytes to codepoints.
abstract class Utf32BytesDecoder implements ListRangeIterator {

  final ListRangeIterator utf32EncodedBytesIterator;
  final int replacementCodepoint;
  int _current = -1;

  Utf32BytesDecoder._fromListRangeIterator(
      this.utf32EncodedBytesIterator, this.replacementCodepoint);

  factory Utf32BytesDecoder(List<int> utf32EncodedBytes,
      [int offset = 0,
      int? length,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
    length ??= utf32EncodedBytes.length - offset;
    if (hasUtf32beBom(utf32EncodedBytes, offset, length)) {
      return Utf32beBytesDecoder(utf32EncodedBytes, offset + 4, length - 4,
          false, replacementCodepoint);
    } else if (hasUtf32leBom(utf32EncodedBytes, offset, length)) {
      return Utf32leBytesDecoder(utf32EncodedBytes, offset + 4, length - 4,
          false, replacementCodepoint);
    } else {
      return Utf32beBytesDecoder(
          utf32EncodedBytes, offset, length, false, replacementCodepoint);
    }
  }

  List<int> decodeRest() {
    var codeunits = List<int>.filled(remaining, -1);
    var i = 0;
    while (moveNext()) {
      codeunits[i++] = current;
    }
    return codeunits;
  }

  @override
  int get current => _current;

  @override
  bool moveNext() {
    _current = -1;
    var remaining = utf32EncodedBytesIterator.remaining;
    if (remaining == 0) {
      _current = -1;
      return false;
    }
    if (remaining < 4) {
      utf32EncodedBytesIterator.skip(utf32EncodedBytesIterator.remaining);
      if (replacementCodepoint != null) {
        _current = replacementCodepoint;
        return true;
      } else {
        throw ArgumentError(
            'Invalid UTF32 at ${utf32EncodedBytesIterator.position}');
      }
    }
    var codepoint = decode();
    if (_validCodepoint(codepoint)) {
      _current = codepoint;
      return true;
    } else if (replacementCodepoint != null) {
      _current = replacementCodepoint;
      return true;
    } else {
      throw ArgumentError(
          'Invalid UTF32 at ${utf32EncodedBytesIterator.position}');
    }
  }

  @override
  int get position => utf32EncodedBytesIterator.position ~/ 4;

  @override
  void backup([int by = 1]) {
    utf32EncodedBytesIterator.backup(4 * by);
  }

  @override
  int get remaining => (utf32EncodedBytesIterator.remaining + 3) ~/ 4;

  @override
  void skip([int count = 1]) {
    utf32EncodedBytesIterator.skip(4 * count);
  }

  int decode();
}

/// Convert UTF-32BE encoded bytes to codepoints by grouping 4 bytes
/// to produce the unicode codepoint.
class Utf32beBytesDecoder extends Utf32BytesDecoder {
  Utf32beBytesDecoder(List<int> utf32EncodedBytes,
      [int offset = 0,
      int? length,
      bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT])
      : super._fromListRangeIterator(
            (ListRange(utf32EncodedBytes, offset, length)).iterator,
            replacementCodepoint) {
    if (stripBom && hasUtf32beBom(utf32EncodedBytes, offset, length)) {
      skip();
    }
  }

  @override
  int decode() {
    utf32EncodedBytesIterator.moveNext();
    var value = utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value = (value << 8) + utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value = (value << 8) + utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value = (value << 8) + utf32EncodedBytesIterator.current;
    return value;
  }
}

/// Convert UTF-32BE encoded bytes to codepoints by grouping 4 bytes
/// to produce the unicode codepoint.
class Utf32leBytesDecoder extends Utf32BytesDecoder {
  Utf32leBytesDecoder(List<int> utf32EncodedBytes,
      [int offset = 0,
      int? length,
      bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT])
      : super._fromListRangeIterator(
            (ListRange(utf32EncodedBytes, offset, length)).iterator,
            replacementCodepoint) {
    if (stripBom && hasUtf32leBom(utf32EncodedBytes, offset, length)) {
      skip();
    }
  }

  @override
  int decode() {
    utf32EncodedBytesIterator.moveNext();
    var value = utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value += (utf32EncodedBytesIterator.current << 8);
    utf32EncodedBytesIterator.moveNext();
    value += (utf32EncodedBytesIterator.current << 16);
    utf32EncodedBytesIterator.moveNext();
    value += (utf32EncodedBytesIterator.current << 24);
    return value;
  }
}

bool _validCodepoint(int codepoint) {
  return (codepoint >= 0 && codepoint < UNICODE_UTF16_RESERVED_LO) ||
      (codepoint > UNICODE_UTF16_RESERVED_HI &&
          codepoint < UNICODE_VALID_RANGE_MAX);
}
