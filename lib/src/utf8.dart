library utf_convert.utf8;

import 'dart:collection';

import 'constants.dart';
import 'list_range.dart';
import 'shared.dart';

const int _UTF8_ONE_BYTE_MAX = 0x7f;
const int _UTF8_TWO_BYTE_MAX = 0x7ff;
const int _UTF8_THREE_BYTE_MAX = 0xffff;

const int _UTF8_LO_SIX_BIT_MASK = 0x3f;

const int _UTF8_FIRST_BYTE_OF_TWO_BASE = 0xc0;
const int _UTF8_FIRST_BYTE_OF_THREE_BASE = 0xe0;
const int _UTF8_FIRST_BYTE_OF_FOUR_BASE = 0xf0;
const int _UTF8_FIRST_BYTE_OF_FIVE_BASE = 0xf8;
const int _UTF8_FIRST_BYTE_OF_SIX_BASE = 0xfc;

const int _UTF8_FIRST_BYTE_OF_TWO_MASK = 0x1f;
const int _UTF8_FIRST_BYTE_OF_THREE_MASK = 0xf;
const int _UTF8_FIRST_BYTE_OF_FOUR_MASK = 0x7;

const int _UTF8_FIRST_BYTE_BOUND_EXCL = 0xfe;
const int _UTF8_SUBSEQUENT_BYTE_BASE = 0x80;

/// Decodes the UTF-8 bytes as an iterable. Thus, the consumer can only convert
/// as much of the input as needed. Set the replacementCharacter to null to
/// throw an ArgumentError rather than replace the bad value.
IterableUtf8Decoder decodeUtf8AsIterable(List<int> bytes,
    [int offset = 0,
    int length = -1,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return IterableUtf8Decoder(bytes, offset, length, replacementCodepoint);
}

/// Produce a String from a List of UTF-8 encoded bytes. The parameters
/// can set an offset into a list of bytes (as int), limit the length of the
/// values to be decoded, and override the default Unicode replacement character.
/// Set the replacementCharacter to null to throw an ArgumentError
/// rather than replace the bad value.
String decodeUtf8(List<int> bytes,
    [int offset = 0,
    int? length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return String.fromCharCodes(
      (Utf8Decoder(bytes, offset, length, replacementCodepoint)).decodeRest());
}

/// Produce a sequence of UTF-8 encoded bytes from the provided string.
List<int> encodeUtf8(String str) => codepointsToUtf8(stringToCodepoints(str));

int _addToEncoding(int offset, int bytes, int value, List<int> buffer) {
  while (bytes > 0) {
    buffer[offset + bytes] =
        _UTF8_SUBSEQUENT_BYTE_BASE | (value & _UTF8_LO_SIX_BIT_MASK);
    value = value >> 6;
    bytes--;
  }
  return value;
}

/// Encode code points as UTF-8 code units.
List<int> codepointsToUtf8(List<int> codepoints,
    [int offset = 0, int? length]) {
  var source = ListRange(codepoints, offset, length);

  var encodedLength = 0;
  for (var value in source) {
    if (value < 0 || value > UNICODE_VALID_RANGE_MAX) {
      encodedLength += 3;
    } else if (value <= _UTF8_ONE_BYTE_MAX) {
      encodedLength++;
    } else if (value <= _UTF8_TWO_BYTE_MAX) {
      encodedLength += 2;
    } else if (value <= _UTF8_THREE_BYTE_MAX) {
      encodedLength += 3;
    } else if (value <= UNICODE_VALID_RANGE_MAX) {
      encodedLength += 4;
    }
  }

  var encoded = List<int>.filled(encodedLength, -1);
  var insertAt = 0;
  for (var value in source) {
    if (value < 0 || value > UNICODE_VALID_RANGE_MAX) {
      encoded.setRange(insertAt, insertAt + 3, [0xef, 0xbf, 0xbd]);
      insertAt += 3;
    } else if (value <= _UTF8_ONE_BYTE_MAX) {
      encoded[insertAt] = value;
      insertAt++;
    } else if (value <= _UTF8_TWO_BYTE_MAX) {
      encoded[insertAt] = _UTF8_FIRST_BYTE_OF_TWO_BASE |
          (_UTF8_FIRST_BYTE_OF_TWO_MASK &
              _addToEncoding(insertAt, 1, value, encoded));
      insertAt += 2;
    } else if (value <= _UTF8_THREE_BYTE_MAX) {
      encoded[insertAt] = _UTF8_FIRST_BYTE_OF_THREE_BASE |
          (_UTF8_FIRST_BYTE_OF_THREE_MASK &
              _addToEncoding(insertAt, 2, value, encoded));
      insertAt += 3;
    } else if (value <= UNICODE_VALID_RANGE_MAX) {
      encoded[insertAt] = _UTF8_FIRST_BYTE_OF_FOUR_BASE |
          (_UTF8_FIRST_BYTE_OF_FOUR_MASK &
              _addToEncoding(insertAt, 3, value, encoded));
      insertAt += 4;
    }
  }
  return encoded;
}

// Because UTF-8 specifies byte order, we do not have to follow the pattern
// used by UTF-16 & UTF-32 regarding byte order.
List<int> utf8ToCodepoints(List<int> utf8EncodedBytes,
    [int offset = 0,
    int? length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return Utf8Decoder(utf8EncodedBytes, offset, length, replacementCodepoint)
      .decodeRest();
}

/// Return type of [decodeUtf8AsIterable] and variants. The Iterable type
/// provides an iterator on demand and the iterator will only translate bytes
/// as requested by the user of the iterator. (Note: results are not cached.)

class IterableUtf8Decoder extends IterableBase<int> {
  final List<int> bytes;
  final int offset;
  @override
  final int length;
  final int replacementCodepoint;

  IterableUtf8Decoder(this.bytes,
      [this.offset = 0,
      this.length = -1,
      this.replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]);

  @override
  Utf8Decoder get iterator => Utf8Decoder(
      bytes, offset, length == -1 ? null : length, replacementCodepoint);
}

/// Provides an iterator of Unicode codepoints from UTF-8 encoded bytes. The
/// parameters can set an offset into a list of bytes (as int), limit the length
/// of the values to be decoded, and override the default Unicode replacement
/// character. Set the replacementCharacter to null to throw an
/// ArgumentError rather than replace the bad value. The return value
/// from this method can be used as an Iterable (e.g. in a for-loop).
class Utf8Decoder implements Iterator<int> {
  final ListRangeIterator utf8EncodedBytesIterator;
  final int replacementCodepoint;
  int _current = -1;

  Utf8Decoder(List<int> utf8EncodedBytes,
      [int offset = 0,
      int? length,
      this.replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT])
      : utf8EncodedBytesIterator =
            (ListRange(utf8EncodedBytes, offset, length)).iterator;

  // Decode the remainder of the characters in this decoder
  //into a [List<int>].
  List<int> decodeRest() {
    var codepoints = List<int>.filled(utf8EncodedBytesIterator.remaining, -1);
    var i = 0;
    while (moveNext()) {
      codepoints[i++] = current;
    }
    if (i == codepoints.length) {
      return codepoints;
    } else {
      var truncCodepoints = List<int>.filled(i, -1);
      truncCodepoints.setRange(0, i, codepoints);
      return truncCodepoints;
    }
  }

  @override
  int get current => _current;

  @override
  bool moveNext() {
    _current = -1;

    if (!utf8EncodedBytesIterator.moveNext()) return false;

    var value = utf8EncodedBytesIterator.current;
    var additionalBytes = 0;

    if (value < 0) {
      if (replacementCodepoint != null) {
        _current = replacementCodepoint;
        return true;
      } else {
        throw ArgumentError(
            'Invalid UTF8 at ${utf8EncodedBytesIterator.position}');
      }
    } else if (value <= _UTF8_ONE_BYTE_MAX) {
      _current = value;
      return true;
    } else if (value < _UTF8_FIRST_BYTE_OF_TWO_BASE) {
      if (replacementCodepoint != null) {
        _current = replacementCodepoint;
        return true;
      } else {
        throw ArgumentError(
            'Invalid UTF8 at ${utf8EncodedBytesIterator.position}');
      }
    } else if (value < _UTF8_FIRST_BYTE_OF_THREE_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_TWO_BASE;
      additionalBytes = 1;
    } else if (value < _UTF8_FIRST_BYTE_OF_FOUR_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_THREE_BASE;
      additionalBytes = 2;
    } else if (value < _UTF8_FIRST_BYTE_OF_FIVE_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_FOUR_BASE;
      additionalBytes = 3;
    } else if (value < _UTF8_FIRST_BYTE_OF_SIX_BASE) {
      value -= _UTF8_FIRST_BYTE_OF_FIVE_BASE;
      additionalBytes = 4;
    } else if (value < _UTF8_FIRST_BYTE_BOUND_EXCL) {
      value -= _UTF8_FIRST_BYTE_OF_SIX_BASE;
      additionalBytes = 5;
    } else if (replacementCodepoint != null) {
      _current = replacementCodepoint;
      return true;
    } else {
      throw ArgumentError(
          'Invalid UTF8 at ${utf8EncodedBytesIterator.position}');
    }
    var j = 0;
    while (j < additionalBytes && utf8EncodedBytesIterator.moveNext()) {
      var nextValue = utf8EncodedBytesIterator.current;
      if (nextValue > _UTF8_ONE_BYTE_MAX &&
          nextValue < _UTF8_FIRST_BYTE_OF_TWO_BASE) {
        value = ((value << 6) | (nextValue & _UTF8_LO_SIX_BIT_MASK));
      } else {
        // if sequence-starting code unit, reposition cursor to start here
        if (nextValue >= _UTF8_FIRST_BYTE_OF_TWO_BASE) {
          utf8EncodedBytesIterator.backup();
        }
        break;
      }
      j++;
    }
    var validSequence = (j == additionalBytes &&
        (value < UNICODE_UTF16_RESERVED_LO ||
            value > UNICODE_UTF16_RESERVED_HI));
    var nonOverlong = (additionalBytes == 1 && value > _UTF8_ONE_BYTE_MAX) ||
        (additionalBytes == 2 && value > _UTF8_TWO_BYTE_MAX) ||
        (additionalBytes == 3 && value > _UTF8_THREE_BYTE_MAX);
    var inRange = value <= UNICODE_VALID_RANGE_MAX;
    if (validSequence && nonOverlong && inRange) {
      _current = value;
      return true;
    } else if (replacementCodepoint != null) {
      _current = replacementCodepoint;
      return true;
    } else {
      throw ArgumentError(
          'Invalid UTF8 at ${utf8EncodedBytesIterator.position - j}');
    }
  }
}
