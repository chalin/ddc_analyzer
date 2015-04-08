// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.public_api_lint;

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/services/public_api_lint.dart';
import 'package:unittest/unittest.dart';

import '../generated/test_support.dart';
import '../generated/resolver_test.dart';
import '../reflective_tests.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/analyzer.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(PublicApiLintVisitorTest);
}

@reflectiveTest
class PublicApiLintVisitorTest extends ResolverTestCase {
  /**
   * The listener used to gather lint violations. This field is not initialized
   * until [runLint] has been invoked.
   */
  GatheringErrorListener listener;

  void test_classDeclaration_inherited_single_extends() {
    Source source = addPackageSource('test.dart', r'''
class _Private {
  _Private field;
}
class Public extends _Private {}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.INHERITS_INVALID_MEMBER]);
  }

  void test_classDeclaration_inherited_single_implements() {
    Source source = addPackageSource('test.dart', r'''
class _Private {
  _Private field;
}
class Public implements _Private {}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.INHERITS_INVALID_MEMBER]);
  }

  void test_classDeclaration_inherited_single_mixin() {
    Source source = addPackageSource('test.dart', r'''
class _Private {
  _Private field;
}
class Public extends Object with _Private {}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.INHERITS_INVALID_MEMBER]);
  }

  void test_classDeclaration_inherited_multiple_extends() {
    Source source = addPackageSource('test.dart', r'''
class _Private {
  _Private field;
  _Private method(_Private p) {}
}
class Public extends _Private {}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.INHERITS_INVALID_MEMBERS]);
  }

  void test_classDeclaration_private() {
    Source source = addPackageSource('test.dart', r'''
class _Private {
  _Private field;
  _Private method(_Private p) {}
}
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_fieldDeclaration_public_invalid() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
class Public {
  _Private field;
}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_fieldDeclaration_public_valid() {
    Source source = addPackageSource('test.dart', r'''
class Public {
  String field;
}
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_fieldDeclaration_private() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
class Public {
  _Private _field;
}
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_functionDeclaration_public_invalid_returnType() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
_Private function(String s) {}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_functionDeclaration_public_invalid_parameterType() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
String function(_Private p) {}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_functionDeclaration_public_valid() {
    Source source = addPackageSource('test.dart', r'''
class Public {}
String function(Public x) {}
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_functionDeclaration_private() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
_Private _function() {}
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_functionTypeAlias_public_invalid_returnType() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
typedef _Private Function(String s);
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_functionTypeAlias_public_invalid_parameterType() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
typedef String Function(_Private x);
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_functionTypeAlias_public_valid() {
    Source source = addPackageSource('test.dart', r'''
class Public {}
typedef String Function(Public x);
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_functionTypeAlias_private() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
typedef _Private _Function();
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_methodDeclaration_public_invalid_returnType() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
class Public {
  _Private method(String s) {}
}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_methodDeclaration_public_invalid_parameterType() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
class Public {
  String method(_Private p) {}
}
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_methodDeclaration_public_valid() {
    Source source = addPackageSource('test.dart', r'''
class Public {
  String method(String s) {}
}
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_methodDeclaration_private() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
class Public {
  _Private _method() {}
}
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_topLevelVariable_public_invalid() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
_Private variable;
''');
    runLint(source);
    listener.assertErrorsWithCodes([PublicApiLintVisitor.PRIVATE_TYPE_REFERENCE]);
  }

  void test_topLevelVariable_private() {
    Source source = addPackageSource('test.dart', r'''
class _Private {}
_Private _variable;
''');
    runLint(source);
    listener.assertNoErrors();
  }

  void test_topLevelVariable_public_valid() {
    Source source = addPackageSource('test.dart', r'''
class Public {}
Public variable;
''');
    runLint(source);
    listener.assertNoErrors();
  }

  Source addPackageSource(String relativePath, String content) {
    return new TestSourceWithUri('/myPackage/lib/$relativePath', Uri.parse('package:myPackage/$relativePath'), content);
  }

  void runLint(Source source) {
    LibraryElement element = resolve(source);
    CompilationUnit unit = resolveCompilationUnit(source, element);
    listener = new GatheringErrorListener();
    PublicApiLintVisitor visitor = new PublicApiLintVisitor(new ErrorReporter(listener, source));
    unit.accept(visitor);
  }
}
