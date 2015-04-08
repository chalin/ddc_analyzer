library work_in_progress;

import 'dart:math' as math;

import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_engine.dart';

/**
 * An `IncrementalScanner` is a scanner that scans a subset of a string and
 * inserts the resulting tokens into the middle of an existing token stream.
 */
class IncrementalScanner {
  /**
   * The source being scanned.
   */
  final Source source;

  /**
   * The reader used to access the characters in the source.
   */
  final CharacterReader reader;

  /**
   * The error listener that will be informed of any errors that are found
   * during the scan.
   *
   * TODO(brianwilkerson) Replace this with a list of errors so that we can
   * update the errors.
   */
  final AnalysisErrorListener errorListener;

  /**
   * The token immediately to the left of the range of tokens that were
   * modified.
   */
  Token leftToken;

  /**
   * The token immediately to the right of the range of tokens that were
   * modified.
   */
  Token rightToken;

  /**
   * A flag indicating whether there were any non-comment tokens changed (other
   * than having their position updated) as a result of the modification.
   */
  bool hasNonWhitespaceChange = false;

  /**
   * Initialize a newly created scanner to scan characters within the given
   * [source]. The content of the source can be read using the given [reader].
   * Any errors that are found will be reported to the given [errorListener].
   */
  IncrementalScanner(this.source, this.reader, this.errorListener);

  /**
   * Given the [stream] of tokens scanned from the original source, the modified
   * source (the result of replacing one contiguous range of characters with
   * another string of characters), and a specification of the modification that
   * was made, update the token stream to reflect the modified source. Return
   * the first token in the updated token stream.
   *
   * The [stream] is expected to be the first non-EOF token in the token stream.
   *
   * The modification is specified by the [index] of the first character in both
   * the original and modified source that was affected by the modification, the
   * number of characters removed from the original source (the [removedLength])
   * and the number of characters added to the modified source (the
   * [insertedLength]).
   */
  Token rescan(Token stream, int index, int removedLength, int insertedLength) {
    Token leftEof = stream.previous;
    //
    // Compute the delta between the character index of characters after the
    // modified region in the original source and the index of the corresponding
    // character in the modified source.
    //
    int delta = insertedLength - removedLength;
    //
    // Skip past the tokens whose end is less than the replacement start. (If
    // the replacement start is equal to the end of an existing token, then it
    // means that the existing token might have been modified, so we need to
    // rescan it.)
    //
    while (stream.type != TokenType.EOF && stream.end < index) {
      stream = stream.next;
    }
    Token oldLeftToken = stream.previous;
    Token oldFirst = stream;
    //
    // Skip past tokens until we find a token whose offset is greater than the
    // end of the removed region. (If the end of the removed region is equal to
    // the beginning of an existing token, then it means that the existing token
    // might have been modified, so we need to rescan it.)
    //
    int removedEnd = index + (removedLength == 0 ? 0 : removedLength - 1);
    while (stream.type != TokenType.EOF && stream.offset <= removedEnd) {
      stream = stream.next;
    }
    //
    // Figure out which region of characters actually needs to be re-scanned.
    //
// =====
    if (stream == oldFirst) {
      // The text was changed between two non-comment tokens.
      leftToken = oldLeftToken;
      rightToken = oldFirst;
      hasNonWhitespaceChange = false;
      return _scanBetweenTokens(oldLeftToken, oldFirst, delta);
    }
// =====
    Token oldLast;
    Token oldRightToken;
    if (stream.type != TokenType.EOF && removedEnd + 1 == stream.offset) {
      oldLast = stream;
      stream = stream.next;
      oldRightToken = stream;
    } else {
      oldLast = stream.previous;
      oldRightToken = stream;
    }
    //
    // Compute the range of characters that are known to need to be rescanned.
    // If the index is within an existing token, then we need to start at the
    // beginning of the token.
    //
    int scanStart = math.max(oldFirst.previous.end, 0);
    int scanEnd = oldLast.end + delta;
    //
    // Starting at the start of the scan region, scan tokens from the modified
    // source until the end of the just scanned token is greater than or equal
    // to end of the scan region in the modified source. Include trailing
    // characters of any token that was split as a result of inserted text, as
    // in "ab" --> "a.b".
    //
    Token replacementStart = _scanRange(scanStart, scanEnd);
//    Token newFirst = replacement;
//    Token newLast = _findEof(replacement).previous;
    hasNonWhitespaceChange =
        _hasNonWhitespaceToken(replacementStart, _findEof(replacementStart));
    //
    // If some of the tokens at the beginning or end of the modified region did
    // not change, then effectively remove them from the modified region in
    // order to reduce the amount of code that needs to be reparsed. For
    // example, in "a; c;" --> "a;b c;", the leftToken was ";", but this code
    // advances it to "b" since "b" is the first new token.
    //
    Token newFirst = replacementStart;
    while (newFirst.type != TokenType.EOF &&
        !identical(oldFirst, oldRightToken) &&
        _equalTokens(oldFirst, newFirst)) {
      oldLeftToken = oldFirst;
      oldFirst = oldFirst.next;
      leftToken = newFirst;
      newFirst = newFirst.next;
    }
    Token newLast = _findEof(newFirst).previous;
    while (!identical(newLast, leftToken) &&
        !identical(oldLast, oldLeftToken) &&
        newLast.type != TokenType.EOF &&
        _equalTokens(oldLast, newLast)) {
      oldRightToken = oldLast;
      oldLast = oldLast.previous;
      rightToken = newLast;
      newLast = newLast.previous;
    }
    hasNonWhitespaceChange = !identical(leftToken.next, rightToken) ||
        !identical(oldLeftToken.next, oldRightToken);
    // TODO(brianwilkerson) Integrate the new tokens into the token stream.
    //
    // Apply the delta to the tokens after the last new token.
    //
    _updateOffsets(oldRightToken, delta);
    _replace(oldLeftToken, newFirst, newLast, oldRightToken);
    //
    // TODO(brianwilkerson) Update the lineInfo.
    //
    //
    // TODO(brianwilkerson) Begin tokens are not getting associated with the
    //     corresponding end tokens (because the end tokens have not been copied
    //     when we're copying the begin tokens). This could have implications
    //     for parsing.
    //
    return leftEof.next;
  }

  /**
   * Return `true` if any of the token between the [first] and [last],
   * inclusive, are non-eof tokens or if any of them have a preceeding comment
   * that is a documentation comment.
   */
  bool _hasNonWhitespaceToken(Token first, Token last) {
    Token current = first.previous;
    do {
      current = current.next;
      if (current.type != TokenType.EOF) {
        return true;
      }
      Token comment = current.precedingComments;
      while (comment != null) {
        String lexeme = comment.lexeme;
        if (comment.type == TokenType.SINGLE_LINE_COMMENT) {
          if (StringUtilities.startsWith3(
              comment.lexeme, 0, 0x2F, 0x2F, 0x2F)) {
            return true;
          }
        } else {
          if (StringUtilities.startsWith3(
              comment.lexeme, 0, 0x2F, 0x2A, 0x2A)) {
            return true;
          }
        }
        comment = comment.next;
      }
    } while (current != last);
    return false;
  }

  /**
   * Return `true` if the [oldToken] and the [newToken] are equal to each other.
   * For the purposes of the incremental scanner, two tokens are equal if they
   * have the same type and lexeme.
   */
  bool _equalTokens(Token oldToken, Token newToken) =>
      oldToken.type == newToken.type &&
          oldToken.length == newToken.length &&
          oldToken.lexeme == newToken.lexeme;

  /**
   * Given a [token], return the EOF token that follows the token.
   */
  Token _findEof(Token token) {
    while (token.type != TokenType.EOF) {
      token = token.next;
    }
    return token;
  }

  /**
   * Merge the comments from the [newToken] into the [existingToken].
   */
  Token _mergeComments(Token newToken, Token existingToken) {
    var newComments = newToken.precedingComments;
    if (newComments == null) {
      // There are no new comments to add, so there's no work to do.
      return existingToken;
    }
    var existingComments = existingToken.precedingComments;
    if (existingComments != null) {
      // Append the existing comments to the end of the list of new comments.
      Token newCommentsEnd = newComments;
      while (newCommentsEnd.next != null) {
        newCommentsEnd = newCommentsEnd.next;
      }
      newCommentsEnd.setNext(existingComments);
    }
//    Token copy = existingToken.copyWithComments(newComments);
//    existingToken.previous.setNext(copy);
//    copy.setNext(existingToken.next);
//    return copy;
    return null;
  }

  void _replace(Token oldLeft, Token newFirst, Token newLast, Token oldRight) {
    oldLeft.setNext(newFirst);
    newLast.setNext(oldRight);
  }

  /**
   * Scan the token between the [start] (inclusive) and [end] (exclusive)
   * offsets.
   */
  Token _scanRange(int start, int end) {
    Scanner scanner = new Scanner(
        source, new CharacterRangeReader(reader, start, end), errorListener);
    return scanner.tokenize();
  }

  /**
   * The changes were all between two adjacent non-comment tokens. Scan the
   * modified region and insert the new tokens between the previously existing
   * tokens.
   */
  Token _scanBetweenTokens(Token left, Token right, int delta) {
    Token replacement = _scanRange(left.end, right.offset);
    //
    // If there are any new non-comment tokens to be inserted, insert them into
    // the token stream after the left token.
    //
    if (replacement.type != TokenType.EOF) {
      left.setNext(replacement);
      replacement = replacement.next;
      while (replacement.type != TokenType.EOF) {
        replacement = replacement.next;
      }
      replacement.previous.setNext(right);
    }
    _updateOffsets(right, delta);
    //
    // Now look for any comment tokens that need to be associated with the right
    // token.
    //
//    Token newComments = replacement.precedingComments;
//    if (newComments == null) {
//      // There are no comment tokens, so remove the old ones if they exist.
//      if (right.precedingComments != null) {
//        Token newRight = right.copyWithoutComments();
//        newRight.setNext(right.next);
//        left.setNext(newRight);
//      }
//    } else {
//      // There are comment tokens, so associate them with the right token.
//      Token newRight = right.copyWithComments(replacement.precedingComments);
//      newRight.setNext(right.next);
//      left.setNext(newRight);
//    }
    return left;
  }

  /**
   * Update the offsets of every token from the given [token] to the end of the
   * stream by adding the given [delta].
   */
  void _updateOffsets(Token token, int delta) {
    while (token.type != TokenType.EOF) {
      token.offset += delta;
      Token comment = token.precedingComments;
      while (comment != null) {
        comment.offset += delta;
        comment = comment.next;
      }
      token = token.next;
    }
    token.offset += delta;
  }
}

/**
 * A `CharacterRangeReader` is a [CharacterReader] that reads a range of
 * characters from another character reader.
 */
class CharacterRangeReader extends CharacterReader {
  /**
   * The reader from which the characters are actually being read.
   */
  final CharacterReader baseReader;

  /**
   * The last character to be read.
   */
  final int endIndex;

  /**
   * Initialize a newly created reader to read the characters from the given
   * [baseReader] between the [startIndex] (inclusive) to [endIndex] (exclusive).
   */
  CharacterRangeReader(this.baseReader, int startIndex, this.endIndex) {
    baseReader.offset = startIndex - 1;
  }

  @override
  int advance() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.advance();
  }

  @override
  int get offset => baseReader.offset;

  @override
  String getString(int start, int endDelta) =>
      baseReader.getString(start, endDelta);

  @override
  void set offset(int offset) {
    baseReader.offset = offset;
  }

  @override
  int peek() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.peek();
  }
}

//class TokenEx {
//
//  /**
//   * Return a newly created token that is a copy of this token but with the
//   * given comments. The token that is returned will not be a part of any token
//   * stream.
//   */
//  Token copyWithComments(Token comments) =>
//      new TokenWithComment(type, offset, comments);
//
//  /**
//   * Return a newly created token that is a copy of this token but without any
//   * comments. The token that is returned will not be a part of any token
//   * stream.
//   */
//  Token copyWithoutComments() => new Token(type, offset);
//}
//
//class BeginTokenEx {
//  @override
//  Token copyWithComments(Token comments) =>
//      new BeginTokenWithComment(type, offset, comments);
//
//  @override
//  Token copyWithoutComments() => new BeginToken(type, offset);
//}
//
//class KeywordTokenEx {
//  @override
//  Token copyWithComments(Token comments) =>
//      new KeywordTokenWithComment(keyword, offset, comments);
//
//  @override
//  Token copyWithoutComments() => new KeywordToken(keyword, offset);
//}
//
//class StringTokenEx {
//  @override
//  Token copyWithComments(Token comments) =>
//      new StringTokenWithComment(type, _value, offset, comments);
//
//  @override
//  Token copyWithoutComments() => new StringToken(type, _value, offset);
//}
