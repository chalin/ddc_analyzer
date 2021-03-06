// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.general_test;

import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisTask, GetContentTask;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(GetContentTaskTest);
}

@reflectiveTest
class GetContentTaskTest extends EngineTestCase {
  test_buildInputs() {
    AnalysisTarget target = new TestSource();
    Map<String, TaskInput> inputs = GetContentTask.buildInputs(target);
    expect(inputs, isEmpty);
  }

  test_constructor() {
    AnalysisContext context = new _MockContext();
    AnalysisTarget target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_createTask() {
    AnalysisContext context = new _MockContext();
    AnalysisTarget target = new TestSource();
    GetContentTask task = GetContentTask.createTask(context, target);
    expect(task, isNotNull);
    expect(task.context, context);
    expect(task.target, target);
  }

  test_descriptor() {
    AnalysisContext context = new _MockContext();
    AnalysisTarget target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    expect(task.descriptor, GetContentTask.DESCRIPTOR);
  }

  test_perform() {
    AnalysisContext context = new _MockContext();
    Source target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    when(context.getContents(target))
        .thenReturn(new TimestampedData<String>(42, 'foo'));
    task.perform();
    expect(task.caughtException, isNull);
    expect(task.outputs, hasLength(2));
    expect(task.outputs[CONTENT], 'foo');
    expect(task.outputs[MODIFICATION_TIME], 42);
  }

  void test_perform_exception() {
    AnalysisContext context = new _MockContext();
    Source target = new TestSource();
    GetContentTask task = new GetContentTask(context, target);
    when(context.getContents(target)).thenThrow('My exception!');
    task.perform();
    expect(task.caughtException, isNotNull);
    expect(task.outputs, isEmpty);
  }
}

class _MockContext extends TypedMock implements AnalysisContext {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
