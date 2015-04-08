// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library src.services.public_api_lint;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart'; // TODO(brianwilkerson) Figure out how to remove this!
import 'package:analyzer/src/services/lint.dart';

/**
 * A linter used to find problems in the declarations of public API's. Every
 * file that is in the 'lib' folder but not in the 'src' folder is considered
 * to contain public API. This API must be usable without needing to refer to
 * any non-public types.
 */
class PublicApiLint extends Linter {
  @override
  AstVisitor getVisitor() {
    return new PublicApiLintVisitor(reporter);
  }
}

/**
 * A visitor used to produce lint violations for a fully resolved AST structure.
 */
class PublicApiLintVisitor extends RecursiveAstVisitor {
  /**
   * The lint code produced when a type referenced in a public API refers to a
   * private type.
   *
   * Parameters:
   * 0: The name of the invalid inherited member, qualified by the type name
   */
  static const LintCode INHERITS_INVALID_MEMBER = const LintCode(
      'INHERITS_INVALID_MEMBER',
      'Class inherits member with a references to non-public types: {0}');

  /**
   * The lint code produced when a type referenced in a public API refers to a
   * private type.
   *
   * Parameters:
   * 0: The name of the invalid inherited member, qualified by the type name
   */
  static const LintCode INHERITS_INVALID_MEMBERS = const LintCode(
      'INHERITS_INVALID_MEMBERS',
      'Class inherits members with references to non-public types: {0}');

  /**
   * The lint code produced when a type referenced in a public API refers to a
   * private type.
   *
   * Parameters:
   * 0: The name of the non-public type being referenced
   */
  static const LintCode PRIVATE_TYPE_REFERENCE = const LintCode(
      'PRIVATE_TYPE_REFERENCE',
      'Reference to non-public type {0} in a public API');

  /**
   * The error reporter used to report lint violations.
   */
  ErrorReporter reporter;

  /**
   * Initialize a newly created visitor to produce lint violations for the fully
   * resolved AST structure being visited.
   */
  PublicApiLintVisitor(this.reporter);

  /**
   * Given a map containing [members] that are inherited by some class, add to
   * the given list of [invalidMembers] all of the members from the map that are
   * invalid because they references at least one non-public type.
   */
  void addInvalidMembers(
      MemberMap members, List<ExecutableElement> invalidMembers) {
    int size = members.size;
    for (int i = 0; i < size; i++) {
      ExecutableElement member = members.getValue(i);
      if (isInvalidMember(member)) {
        if (member.isSynthetic) {
          if (member is PropertyAccessorElement && member.isGetter) {
            invalidMembers.add(member);
          }
        } else {
          invalidMembers.add(member);
        }
      }
    }
  }

  /**
   * Return `true` if all of the variables in the given [variableList] have
   * library private names.
   */
  bool allPrivate(VariableDeclarationList variableList) {
    for (VariableDeclaration variable in variableList.variables) {
      if (!Identifier.isPrivateName(variable.name.name)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if the given [member] is invalid because it references a
   * non-public type.
   */
  bool isInvalidMember(ExecutableElement member) {
    if (Identifier.isPrivateName(member.name)) {
      return false;
    }
    if (isInvalidType(member.returnType)) {
      return true;
    }
    for (ParameterElement parameter in member.parameters) {
      if (isInvalidType(parameter.type)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [type] is not part of the public API.
   */
  bool isInvalidType(DartType type) {
    if (type == null || type.isBottom || type.isDynamic || type.isUndefined || type.isVoid) {
      return false;
    }
    if (Identifier.isPrivateName(type.name)) {
      return true;
    }
    if (!isPublic(type.element.source)) {
      return true;
    }
    if (type is FunctionType) {
      if (isInvalidType(type.returnType)) {
        return true;
      }
      for (ParameterElement parameter in type.parameters) {
        if (isInvalidType(parameter.type)) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Return `true` if the given [source] is in the 'lib' directory, but not in
   * the 'src' directory.
   */
  bool isPublic(Source source) {
    if (source == null) {
      return false;
    }
    Uri uri = source.uri;
    String scheme = uri.scheme;
    if (scheme == DartUriResolver.DART_SCHEME) {
      return true;
    }
    String path = source.fullName;
    if (scheme == PackageUriResolver.PACKAGE_SCHEME) {
      return uri.path.indexOf('/src/') < 0;
    }
    // TODO(brianwilkerson) Handle custom URI schemes.
    return path.indexOf('/lib/') >= 0 && path.indexOf('/lib/src/') < 0;
  }

  /**
   * Verify that all of the types of the parameters in the given [parameterList]
   * are part of the public API.
   */
  void verifyParameters(FormalParameterList parameterList) {
    if (parameterList != null) {
      for (FormalParameter parameter in parameterList.parameters) {
        verifyParameter(parameter);
      }
    }
  }

  void verifyParameter(FormalParameter parameter) {
    NormalFormalParameter normalParameter;
    if (parameter is DefaultFormalParameter) {
      normalParameter = parameter.parameter;
    } else {
      normalParameter = parameter;
    }
    if (normalParameter is SimpleFormalParameter) {
      verifyTypeName(normalParameter.type);
    } else if (normalParameter is FunctionTypedFormalParameter) {
      verifyTypeName(normalParameter.returnType);
      verifyParameters(normalParameter.parameters);
    }
  }

  /**
   * Verify that the given [type] is part of the public API. If not, create a
   * lint violation and associate it with the given node.
   */
  void verifyType(DartType type, AstNode node) {
    if (type == null) {
      return;
    }
    String name = type.name;
    if (Identifier.isPrivateName(name)) {
      reporter.reportErrorForNode(PRIVATE_TYPE_REFERENCE, node, [name]);
      return;
    }
    Element element = type.element;
    if (element != null) {
      Source source = element.source;
      if (!isPublic(source)) {
        if (source != null) {
          name = '$name (uri="${source.uri}", path="${source.fullName}")';
        }
        reporter.reportErrorForNode(PRIVATE_TYPE_REFERENCE, node, [name]);
        return;
      }
    }
  }

  /**
   * Verify that the type referenced by the given [typeName] is part of the
   * public API.
   */
  void verifyTypeName(TypeName typeName) {
    if (typeName == null) {
      return;
    }
    verifyType(typeName.type, typeName);
    TypeArgumentList arguments = typeName.typeArguments;
    if (arguments != null) {
      for (TypeName typeArgument in arguments.arguments) {
        verifyTypeName(typeArgument);
      }
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    super.visitClassDeclaration(node);
    ClassElement element = node.element;
    if (element == null) {
      return;
    }
    List<ExecutableElement> invalidMembers = <ExecutableElement>[];
    InheritanceManager manager = new InheritanceManager(element.library);
    MemberMap map = manager.getMapOfMembersInheritedFromInterfaces(element);
    addInvalidMembers(map, invalidMembers);
    int count = invalidMembers.length;
    if (count == 1) {
      StringBuffer buffer = new StringBuffer();
      ExecutableElement member = invalidMembers[0];
      buffer.write(member.enclosingElement.name);
      buffer.write('.');
      buffer.write(member.name);
      reporter.reportErrorForNode(
          INHERITS_INVALID_MEMBER, node.name, [buffer.toString()]);
    } else if (count > 1) {
      StringBuffer buffer = new StringBuffer();
      for (int i = 0; i < count; i++) {
        if (i > 0) {
          buffer.write(', ');
        }
        ExecutableElement member = invalidMembers[i];
        buffer.write(member.enclosingElement.name);
        buffer.write('.');
        buffer.write(member.name);
      }
      reporter.reportErrorForNode(
          INHERITS_INVALID_MEMBERS, node.name, [buffer.toString()]);
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (!isPublic(node.element.source)) {
      // Don't run this lint over non-public sources.
      return;
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (allPrivate(node.fields)) {
      return;
    }
    verifyTypeName(node.fields.type);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    verifyTypeName(node.returnType);
    verifyParameters(node.functionExpression.parameters);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    verifyTypeName(node.returnType);
    verifyParameters(node.parameters);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    verifyTypeName(node.returnType);
    verifyParameters(node.parameters);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (allPrivate(node.variables)) {
      return;
    }
    verifyTypeName(node.variables.type);
  }
}
