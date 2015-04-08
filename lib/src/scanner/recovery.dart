// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.scanner.recovery;

import 'package:analyzer/src/generated/scanner.dart';
import 'dart:collection';

/**
 * An instance of `ExtractedTokens` represents the opening and closing tokens
 * found in a given range of tokens.
 */
class ExtractedTokens {
  /**
   * The opening and closing tokens that were extracted.
   */
  List<Token> tokens;

  /**
   * The number of open curly bracket ('{') tokens that were extracted.
   */
  int openCurlyBracketCount = 0;

  /**
   * The number of open parenthesis ('(') tokens that were extracted.
   */
  int openParenCount = 0;

  /**
   * The number of open square bracket ('[') tokens that were extracted.
   */
  int openSquareBracketCount = 0;

  /**
   * The number of close curly bracket ('}') tokens that were extracted.
   */
  int closeCurlyBracketCount = 0;

  /**
   * The number of close parenthesis (')') tokens that were extracted.
   */
  int closeParenCount = 0;

  /**
   * The number of close square bracket (']') tokens that were extracted.
   */
  int closeSquareBracketCount = 0;

  /**
   * Initialize a newly created list of extracted tokens by extract the opening
   * and closing tokens from the given [stream] of tokens.
   */
  ExtractedTokens(Token stream) {
    _extractTokens(stream);
  }

  ExtractedTokens._copy(ExtractedTokens copiedTokens) {
    tokens = new List<Token>.from(copiedTokens.tokens);
    openCurlyBracketCount = copiedTokens.openCurlyBracketCount;
    openParenCount = copiedTokens.openParenCount;
    openSquareBracketCount = copiedTokens.openSquareBracketCount;
    closeCurlyBracketCount = copiedTokens.closeCurlyBracketCount;
    closeParenCount = copiedTokens.closeParenCount;
    closeSquareBracketCount = copiedTokens.closeSquareBracketCount;
  }

  /**
   * Return the token with the given [index].
   */
  Token operator [](int index) => tokens[index];

//  /**
//   * Clear the token with the given [index]. This will not affect the size of
//   * the list, nor the indices used to access tokens within the list
//   */
//  void clear(int index) {
//    Token token = tokens[index];
//    if (token == null) {
//      return;
//    }
//    TokenType type = token.type;
//    if (type == TokenType.OPEN_CURLY_BRACKET) {
//      openCurlyBracketCount--;
//    } else if (type == TokenType.OPEN_PAREN) {
//      openParenCount--;
//    } else if (type == TokenType.OPEN_SQUARE_BRACKET) {
//      openSquareBracketCount--;
//    } else if (type == TokenType.CLOSE_CURLY_BRACKET) {
//      closeCurlyBracketCount--;
//    } else if (type == TokenType.CLOSE_PAREN) {
//      closeParenCount--;
//    } else if (type == TokenType.CLOSE_SQUARE_BRACKET) {
//      closeSquareBracketCount--;
//    }
//  }

  /**
   * Return a copy of this list of extracted tokens.
   */
  ExtractedTokens copy() => new ExtractedTokens._copy(this);

  /**
   * Return the number of tokens that were extracted.
   */
  int get length => tokens.length;

  /**
   * Extract the opening and closing tokens from the given [stream] of tokens.
   */
  void _extractTokens(Token stream) {
    tokens = <Token>[];
    TokenType type = stream.type;
    while (type != TokenType.EOF) {
      if (type == TokenType.OPEN_CURLY_BRACKET) {
        tokens.add(stream);
        openCurlyBracketCount++;
      } else if (type == TokenType.OPEN_PAREN) {
        tokens.add(stream);
        openParenCount++;
      } else if (type == TokenType.OPEN_SQUARE_BRACKET) {
        tokens.add(stream);
        openSquareBracketCount++;
      } else if (type == TokenType.CLOSE_CURLY_BRACKET) {
        tokens.add(stream);
        closeCurlyBracketCount++;
      } else if (type == TokenType.CLOSE_PAREN) {
        tokens.add(stream);
        closeParenCount++;
      } else if (type == TokenType.CLOSE_SQUARE_BRACKET) {
        tokens.add(stream);
        closeSquareBracketCount++;
      }
      stream = stream.next;
      type = stream.type;
    }
  }
}

/**
 * A map from the index of an opening token to the index of the corresponding
 * closing token.
 */
class IndexMap {
  /**
   * The map of opening tokens to closing tokens.
   */
  final Map<int, int> map;

  /**
   * A sorted list of the keys, with the largest index first.
   */
  List<int> sortedKeys;

  /**
   * Return the result of merging the pairs in the [first], [second], and
   * [third] maps. Any or all of the maps can be `null`. If all of the maps are
   * `null`, then `null` will be returned. If two of the maps are null, then the
   * non-`null` map will be returned (without creating a copy). Otherwise, a new
   * map will be created.
   */
  static IndexMap merge(IndexMap first, IndexMap second, IndexMap third) {
    IndexMap _mergeTwo(IndexMap first, IndexMap second) {
      Map<int, int> mergedMap = new HashMap<int, int>();
      mergedMap.addAll(first.map);
      mergedMap.addAll(second.map);
      return new IndexMap(mergedMap);
    }
    if (first == null) {
      if (second == null) {
        return third;
      } else if (third == null) {
        return second;
      }
      return _mergeTwo(second, third);
    } else if (second == null) {
      if (third == null) {
        return first;
      }
      return _mergeTwo(first, third);
    } else if (third == null) {
      return _mergeTwo(first, second);
    }
    Map<int, int> mergedMap = new HashMap<int, int>();
    mergedMap.addAll(first.map);
    mergedMap.addAll(second.map);
    mergedMap.addAll(third.map);
    return new IndexMap(mergedMap);
  }

  IndexMap(this.map);

//  /**
//   * Return `true` if this map contains any pairs that overlap with a pair from
//   * the given [map]. This will only happen when there is a malformed input such
//   * as `"([)]"`.
//   */
//  bool conflictsWith(IndexMap indexMap) {
//    Map<int, int> otherMap = indexMap.map;
//    for (int otherKey in otherMap.keys) {
//      if (_conflictsWithRange(otherKey, otherMap[otherKey])) {
//        return true;
//      }
//    }
//    return false;
//  }

  /**
   * Invoke the function [f] once for each key/value pair, starting with the
   * largest key values first.
   */
  void forEach(void f(int key, int value)) {
    _computeSortedKeys();
    sortedKeys.forEach((int key) {
      f(key, map[key]);
    });
  }

  /**
   * Ensure that the list of sorted keys has been computed.
   */
  void _computeSortedKeys() {
    if (sortedKeys == null) {
      sortedKeys = map.keys.toList();
      sortedKeys.sort((int first, int second) => first - second);
    }
  }

//  /**
//   * Return `true` if this map contains any pairs that overlap with a pair with
//   * the given [start] and [end] indices but doesn't completely contain the
//   * specified pair. This will only happen when there is a malformed input such
//   * as `"([)]"`.
//   */
//  bool _conflictsWithRange(int start, int end) {
//    _computeSortedKeys();
//    int index = 0;
//    while (index < sortedKeys.length) {
//      int beginIndex = sortedKeys[index];
//      int endIndex = map[beginIndex];
//      if ((beginIndex > start && beginIndex < end && endIndex > end) ||
//          (beginIndex < start && endIndex > start && endIndex < end)) {
//        return true;
//      } else if (beginIndex > end) {
//        return false;
//      }
//      index++;
//    }
//    return false;
//  }
}

/**
 * A range of tokens, represented by the indexes of the tokens in a list of
 * extracted tokens.
 */
class Range {
  /**
   * The index of the first group token in the range.
   */
  int first = 0;

  /**
   * The index of the last group token in the range.
   */
  int last = 0;

  /**
   * Initialize a newly created range to represent the tokens between the
   * [first] and [last] index.
   */
  Range(this.first, this.last);
}

/**
 * A `TokenMatcher` matches the opening and closing pairs of tokens in a token
 * stream that contains one or more unbalanced tokens.
 *
 * The algorithm used is based on the following assumptions:
 *
 * 1. It is more likely that the missing token will be a closing token than an
 * opening token.
 *
 * 2. The unbalanced tokens will tend to be relatively close together. In other
 * words, it is common for a developer to type the opening token `t1` and then
 * type another opening token `t2` in the same region of the code before typing
 * the closing token for `t1`, but less common to type an unmatched opening or
 * closing token in one part of the file, then move to a distant portion of the
 * file and again type an unmatched token.
 *
 * 3. If one or two of the three kind of token (curly brackets, parentheses or
 * square brackets) are balanced, then it is more likely that they are correct
 * than that they are unbalanced in a way that makes them appear to be balanced.
 * In other words, cases such as "({)}", while possible, are rare.
 */
class TokenMatcher {
  /**
   * The opening and closing tokens that need to be balanced.
   */
  ExtractedTokens tokens;

  /**
   * Initialize a newly created token matcher.
   */
  TokenMatcher();

  /**
   * Scan through the given token [stream] and match up opening and closing
   * tokens.
   */
  void matchGroups(Token stream) {
    tokens = new ExtractedTokens(stream);
    _matchBalancedPairs();
//    _matchGroupsFromOutsideIn();
  }

  /**
   * Given a mapping ([pairs]) from opening tokens to the balancing end
   * tokens, set the end token for each of the opening tokens.
   */
  void _associatePairs(Map<BeginToken, Token> pairs) {
    pairs.forEach((BeginToken begin, Token end) {
      begin.endToken = end;
    });
  }

  IndexMap _computePairs(TokenType openType, TokenType closeType) {
    Map<int, int> pairs = new HashMap<int, int>();
    List<int> groupingStack = <int>[];
    int index = 0;
    while (index < tokens.length) {
      TokenType type = tokens[index].type;
      if (type == openType) {
        groupingStack.add(index);
      } else if (type == closeType) {
        if (groupingStack.isEmpty) {
          return null;
        }
        pairs[index] = groupingStack.removeLast();
      }
      index++;
    }
    if (!groupingStack.isEmpty) {
      return null;
    }
    return new IndexMap(pairs);
  }

//  /**
//   * Given that exactly one of the three maps is `null`, return `true` if the
//   * pairs in the other two maps overlap, indicating an inconsistent input such
//   * as `"([)]"`.
//   */
//  bool _containsConflict(IndexMap curlyBrackets, IndexMap parens, IndexMap squareBrackets) {
//    if (curlyBrackets == null) {
//      return parens.conflictsWith(squareBrackets);
//    } else if (parens == null) {
//      return curlyBrackets.conflictsWith(squareBrackets);
//    } else {
//      return curlyBrackets.conflictsWith(parens);
//    }
//  }

  void _matchAllPairs(IndexMap pairs) {
    if (pairs != null) {
      pairs.forEach((int key, int value) {
        _matchBetweenPair(key, value);
      });
    }
  }

  void _matchBalancedPairs() {
    //
    // Try matching the pairs by kind, keeping count of the number of kinds of
    // pairs that are balanced.
    //
    int count = 0;
    IndexMap curlyBrackets = null;
    IndexMap parens = null;
    IndexMap squareBrackets = null;
    if (tokens.openCurlyBracketCount == tokens.closeCurlyBracketCount) {
      curlyBrackets = _computePairs(
          TokenType.OPEN_CURLY_BRACKET, TokenType.CLOSE_CURLY_BRACKET);
      if (curlyBrackets != null) {
        count++;
      }
    }
    if (tokens.openParenCount == tokens.closeParenCount) {
      parens = _computePairs(TokenType.OPEN_PAREN, TokenType.CLOSE_PAREN);
      if (parens != null) {
        count++;
      }
    }
    if (tokens.openSquareBracketCount == tokens.closeSquareBracketCount) {
      squareBrackets = _computePairs(
          TokenType.OPEN_SQUARE_BRACKET, TokenType.CLOSE_SQUARE_BRACKET);
      if (squareBrackets != null) {
        count++;
      }
    }
    //
    // If there are no balanced pairs of any kind, then return to try a
    // different strategy.
    //
    if (count == 0) {
      return;
    }
    //
    // If one or two kinds of token can be paired, then assume that those pairs
    // are correct and use them as the basis for matching the other kind(s) of
    // tokens.
    //
    if (count == 1 || count == 2) {
//      if (count == 2 &&
//          _containsConflict(curlyBrackets, parens, squareBrackets)) {
//        // There is at least one pair of tokens that overlaps, so the assumption
//        // on which this strategy is based is not valid.
//        return;
//      }
      _matchAllPairs(IndexMap.merge(curlyBrackets, parens, squareBrackets));
    }
    // TODO(brianwilkerson) Move this to a different strategy.
    //
    // Finally, match pairs that have no unbalanced tokens between them.
    //
    // TODO Implement this
  }

  /**
   * Attempt to pair all of the tokens between the [beginIndex] and [endIndex],
   * exclusive, then pair the tokens at those indices.
   */
  void _matchBetweenPair(int beginIndex, int endIndex) {
    // TODO(brianwilkerson) Implement this.
    BeginToken beginToken = tokens[beginIndex];
    Token endToken = tokens[endIndex];
    beginToken.endToken = endToken;
  }

  int _matchFinalGroups(int first, int last) {
    while (first < last) {
      int newLast = _matchGroupBackward(first, last);
      if (newLast < 0) {
        return last;
      }
      last = newLast;
    }
    return last;
  }

  int _matchGroupBackward(int first, int last) {
    Map<BeginToken, Token> pairs = new HashMap<BeginToken, Token>();
    List<Token> groupingStack = <Token>[];
    int index = last;
    while (index >= first) {
      Token token = tokens[index];
      TokenType type = token.type;
      if (type == TokenType.OPEN_CURLY_BRACKET) {
        if (groupingStack.isEmpty) {
          return -1;
        }
        Token end = groupingStack.removeLast();
        if (end.type != TokenType.CLOSE_CURLY_BRACKET) {
          return -1;
        }
        pairs[token] = end;
        if (groupingStack.isEmpty) {
          _associatePairs(pairs);
          return index - 1;
        }
      } else if (type == TokenType.OPEN_PAREN) {
        if (groupingStack.isEmpty) {
          return -1;
        }
        Token end = groupingStack.removeLast();
        if (end.type != TokenType.CLOSE_PAREN) {
          return -1;
        }
        pairs[token] = end;
        if (groupingStack.isEmpty) {
          _associatePairs(pairs);
          return index - 1;
        }
      } else if (type == TokenType.OPEN_SQUARE_BRACKET) {
        if (groupingStack.isEmpty) {
          return -1;
        }
        Token end = groupingStack.removeLast();
        if (end.type != TokenType.CLOSE_SQUARE_BRACKET) {
          return -1;
        }
        pairs[token] = end;
        if (groupingStack.isEmpty) {
          _associatePairs(pairs);
          return index - 1;
        }
      } else {
        groupingStack.add(token);
      }
      index--;
    }
    return -1;
  }

  int _matchGroupForward(int first, int last) {
    Map<BeginToken, Token> pairs = new HashMap<BeginToken, Token>();
    List<BeginToken> groupingStack = <BeginToken>[];
    int index = first;
    while (index <= last) {
      Token token = tokens[index];
      TokenType type = token.type;
      if (type == TokenType.CLOSE_CURLY_BRACKET) {
        if (groupingStack.isEmpty) {
          return -1;
        }
        Token begin = groupingStack.removeLast();
        if (begin.type != TokenType.OPEN_CURLY_BRACKET) {
          return -1;
        }
        pairs[begin] = token;
        if (groupingStack.isEmpty) {
          _associatePairs(pairs);
          return index + 1;
        }
      } else if (type == TokenType.CLOSE_PAREN) {
        if (groupingStack.isEmpty) {
          return -1;
        }
        Token begin = groupingStack.removeLast();
        if (begin.type != TokenType.OPEN_PAREN) {
          return -1;
        }
        pairs[begin] = token;
        if (groupingStack.isEmpty) {
          _associatePairs(pairs);
          return index + 1;
        }
      } else if (type == TokenType.CLOSE_SQUARE_BRACKET) {
        if (groupingStack.isEmpty) {
          return -1;
        }
        Token begin = groupingStack.removeLast();
        if (begin.type != TokenType.OPEN_SQUARE_BRACKET) {
          return -1;
        }
        pairs[begin] = token;
        if (groupingStack.isEmpty) {
          _associatePairs(pairs);
          return index + 1;
        }
      } else {
        groupingStack.add(token);
      }
      index++;
    }
    return -1;
  }

  void _matchGroupsFromOutsideIn() {
    int first = 0;
    int last = tokens.length - 1;
    while (first < last) {
      int oldFirst = first;
      int oldLast = last;
      first = _matchInitialGroups(first, last);
      last = _matchFinalGroups(first, last);
      Range range = _matchMiddleGroup(first, last);
      if (range != null) {
        first = range.first;
        last = range.last;
      }
      if (first == oldFirst && last == oldLast) {
        // If there was no progress made, then we need to exit in order to
        // prevent an infinite loop.
        return;
      }
    }
  }

  int _matchInitialGroups(int first, int last) {
    while (first < last) {
      int newFirst = _matchGroupForward(first, last);
      if (newFirst < 0) {
        return first;
      }
      first = newFirst;
    }
    return first;
  }

  Range _matchMiddleGroup(int first, int last) {
    if (first == last) {
      return null;
    }
    Token firstToken = tokens[first];
    TokenType firstType = firstToken.type;
    Token lastToken = tokens[last];
    TokenType lastType = lastToken.type;

    if (firstType == TokenType.OPEN_CURLY_BRACKET &&
        lastType == TokenType.CLOSE_CURLY_BRACKET) {
      (firstToken as BeginToken).endToken = lastToken;
      return new Range(first + 1, last - 1);
    } else if (firstType == TokenType.OPEN_PAREN &&
        lastType == TokenType.CLOSE_PAREN) {
      (firstToken as BeginToken).endToken = lastToken;
      return new Range(first + 1, last - 1);
    } else if (firstType == TokenType.OPEN_SQUARE_BRACKET &&
        lastType == TokenType.CLOSE_SQUARE_BRACKET) {
      (firstToken as BeginToken).endToken = lastToken;
      return new Range(first + 1, last - 1);
    }
    // TODO Figure out which of the tokens to abandon.
    return null;
  }
}

/**
 * A `Segment` is a segment within a token stream.
 */
class Segment {
  /**
   * The first token in the segment.
   */
  final Token first;

  /**
   * The last token in the segment.
   */
  final Token last;

  /**
   * Initialize a segment to include all of the tokens between the [first] and
   * [last] tokens, inclusive.
   */
  Segment(this.first, this.last);
}

/**
 * A `SplitStrategy` is used to split a token stream into smaller streams that
 * ought to be matched independently.
 */
class SplitStrategy {
  /**
   * Return a list of the segments within the given token [stream].
   */
  List<Segment> splitStream(Token stream) {
    List<Segment> segments = <Segment>[];
    Token first = stream;
    while (stream.type != TokenType.EOF) {
      if (_isTopLevelSpliter(stream)) {
        segments.add(new Segment(first, stream.previous));
      }
      stream = stream.next;
    }
    return segments;
  }

  bool _isTopLevelSpliter(Token token) {
    if (token.type == TokenType.KEYWORD) {
      Keyword keyword = (token as KeywordToken).keyword;
      if (keyword == Keyword.CLASS) {
        return true;
      }
    }
    return false;
  }
}
