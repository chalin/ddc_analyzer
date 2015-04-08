// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.scanner.recovery.test;

import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/scanner/recovery.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(TokenMatcherTest);
}

class TokenMatcherTest {
  void test_close_nested() {
    Token token = _scan('{{}} }');
    _assertMatches(token, {0: 3, 1: 2});
  }

  void test_close_nestedAndSurrounded() {
    Token token = _scan('{{}} {} }');
    _assertMatches(token, {0: 3, 1: 2, 4: 5});
  }

  void test_close_surrounded() {
    Token token = _scan('{} } {}');
    _assertMatches(token, {0: 1, 3: 4});
  }

  void test_open_nested() {
    Token token = _scan('{ {{}}');
    _assertMatches(token, {1: 4, 2: 3});
  }

  void test_open_nestedAndSurrounded() {
    Token token = _scan('{ {} {{}}');
    _assertMatches(token, {1: 2, 3: 6, 4: 5});
  }

  void test_open_surrounded() {
    Token token = _scan('{} { {}');
    _assertMatches(token, {0: 1, 3: 4});
  }

//  void test_balanced() {
//    '{(){(){}(){(() {})}}';
//  }

  void _assertMatches(Token token, Map<int, int> pairs) {
    TokenMatcher matcher = new TokenMatcher();
    matcher.matchGroups(token);
    List<Token> tokens = _toList(token);
    pairs.forEach((int begin, int end) {
      Token beginToken = tokens[begin];
      if (beginToken is! BeginToken) {
        fail(
            'Expected instance of BeginToken, found ${beginToken.runtimeType}');
      }
      Token actualEnd = (beginToken as BeginToken).endToken;
      if (actualEnd != tokens[end]) {
        int index = tokens.indexOf(actualEnd);
        fail('Expected $begin to be matched to $end but was matched to $index');
      }
    });
  }

  Token _scan(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Token token = _scanWithListener(source, listener);
    listener.assertNoErrors();
    return token;
  }

  Token _scanWithListener(String source, GatheringErrorListener listener) {
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    Token result = scanner.tokenize();
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    return result;
  }

  List<Token> _toList(Token token) {
    List<Token> list = <Token>[];
    while (token.type != TokenType.EOF) {
      list.add(token);
      token = token.next;
    }
    return list;
  }
}
