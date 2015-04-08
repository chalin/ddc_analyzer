library engine.mirror;

import 'dart:collection';
import 'dart:mirrors';

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

class EngineClassMirror extends EngineTypeMirror with ObjectMirrorMixin
    implements ClassMirror {
  EngineClassMirror(InterfaceType type) : super(type);

  // TODO: implement declarations
  @override
  Map<Symbol, DeclarationMirror> get declarations => null;

  ClassElement get element => super.element;

  // TODO: implement instanceMembers
  @override
  Map<Symbol, MethodMirror> get instanceMembers => null;

  @override
  bool get isAbstract => element.isAbstract;

  @override
  bool isSubclassOf(ClassMirror other) {
    return type.isSubtypeOf((other as EngineClassMirror).type);
  }

  // TODO: implement mixin
  @override
  ClassMirror get mixin => null;

  @override
  InstanceMirror newInstance(Symbol constructorName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    return null;
  }

  // TODO: implement staticMembers
  @override
  Map<Symbol, MethodMirror> get staticMembers => null;

  @override
  ClassMirror get superclass {
    InterfaceType supertype = element.supertype;
    if (supertype == null) {
      return null;
    }
    return new EngineClassMirror(supertype);
  }

  @override
  List<ClassMirror> get superinterfaces {
    List<ClassMirror> superinterfaces = <ClassMirror>[];
    for (InterfaceType interface in element.interfaces) {
      superinterfaces.add(new EngineClassMirror(interface));
    }
    return superinterfaces;
  }

  @override
  bool get isEnum => element.isEnum;
}

class EngineCombinatorMirror implements CombinatorMirror {
  NamespaceCombinator combinator;

  EngineCombinatorMirror(this.combinator);

  // TODO: implement identifiers
  @override
  List<Symbol> get identifiers => null;

  // TODO: implement isHide
  @override
  bool get isHide => null;

  // TODO: implement isShow
  @override
  bool get isShow => null;
}

class EngineDeclarationMirror implements DeclarationMirror {
  /**
   * The element representing this declaration.
   */
  Element element;

  /**
   * Initialize a newly created declaration mirror to represent the given element.
   */
  EngineDeclarationMirror(this.element);

  @override
  bool get isPrivate => element.isPrivate;

  // TODO: implement isTopLevel
  @override
  bool get isTopLevel => null;

  @override
  SourceLocation get location => new EngineSourceLocation(element);

  // TODO: implement metadata
  @override
  List<InstanceMirror> get metadata => null;

  // TODO: implement owner
  @override
  DeclarationMirror get owner => null;

  // TODO: implement qualifiedName
  @override
  Symbol get qualifiedName => null;

  @override
  Symbol get simpleName => new Symbol(element.name);
}

abstract class EngineLibraryDependencyMirror
    implements LibraryDependencyMirror {
  UriReferencedElement element;

  EngineLibraryDependencyMirror(this.element);

  @override
  SourceLocation get location => new EngineSourceLocation(element);

  // TODO: implement metadata
  @override
  List<InstanceMirror> get metadata => null;

  @override
  Symbol get prefix => null;

  @override
  LibraryMirror get sourceLibrary => new EngineLibraryMirror(element.library);
}

class ExportMirror extends EngineLibraryDependencyMirror {
  ExportMirror(ExportElement element) : super(element);

  @override
  List<CombinatorMirror> get combinators => <CombinatorMirror>[];

  @override
  ExportElement get element => super.element;

  @override
  bool get isExport => true;

  @override
  bool get isImport => false;

  @override
  LibraryMirror get targetLibrary =>
      new EngineLibraryMirror(element.exportedLibrary);

  // TODO: implement isDeferred
  @override
  bool get isDeferred => null;
}

class ImportMirror extends EngineLibraryDependencyMirror {
  ImportMirror(ImportElement element) : super(element);

  @override
  List<CombinatorMirror> get combinators {
    List<CombinatorMirror> combinators = <CombinatorMirror>[];
    for (NamespaceCombinator combinator in element.combinators) {
      combinators.add(new EngineCombinatorMirror(combinator));
    }
    return combinators;
  }

  @override
  ImportElement get element => super.element;

  @override
  bool get isExport => false;

  @override
  bool get isImport => true;

  @override
  Symbol get prefix {
    PrefixElement prefix = element.prefix;
    if (prefix == null) {
      return null;
    }
    return new Symbol(prefix.name);
  }

  @override
  LibraryMirror get targetLibrary =>
      new EngineLibraryMirror(element.importedLibrary);

  // TODO: implement isDeferred
  @override
  bool get isDeferred => null;
}

class EngineLibraryMirror extends EngineDeclarationMirror
    implements LibraryMirror {
  LibraryElement element;

  EngineLibraryMirror(LibraryElement element) : super(element);

  // TODO: implement declarations
  @override
  Map<Symbol, DeclarationMirror> get declarations => null;

  @override
  InstanceMirror getField(Symbol fieldName) {
    // TODO: implement getField
    return null;
  }

  @override
  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    // TODO: implement invoke
    return null;
  }

  // TODO: implement libraryDependencies
  @override
  List<LibraryDependencyMirror> get libraryDependencies => null;

  @override
  InstanceMirror setField(Symbol fieldName, Object value) {
    // TODO: implement setField
    return null;
  }

  // TODO: implement uri
  @override
  Uri get uri => null;
}

class EngineMirrorSystem extends MirrorSystem {
  InternalAnalysisContext context;
  MethodElement mainMethod;
  Map<Uri, LibraryMirror> _libraryMap;

  EngineMirrorSystem(this.context, this.mainMethod) {
    // TODO(brianwilkerson) Initialize libraries.
    _libraryMap = new HashMap<Uri, LibraryMirror>();
  }

  @override
  TypeMirror get dynamicType => null; // TODO: implement dynamicType

  @override
  IsolateMirror get isolate => null;

  @override
  Map<Uri, LibraryMirror> get libraries => new UnmodifiableMapView(_libraryMap);

  @override
  TypeMirror get voidType => null; // TODO: implement voidType
}

/**
 * A mixin that provides default behavior in a non-executable system.
 */
class ObjectMirrorMixin implements ObjectMirror {
  @override
  InstanceMirror getField(Symbol fieldName) => null;

  @override
  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) => null;

  @override
  InstanceMirror setField(Symbol fieldName, Object value) => null;
}

class EngineTypeMirror extends EngineDeclarationMirror implements TypeMirror {
  DartType type;

  EngineTypeMirror(DartType type)
      : type = type,
        super(type.element);

  @override
  bool get hasReflectedType => false;

  @override
  bool isAssignableTo(TypeMirror other) {
    return type.isAssignableTo((other as EngineTypeMirror).type);
  }

  // TODO: implement isOriginalDeclaration
  @override
  bool get isOriginalDeclaration => null;

  @override
  bool isSubtypeOf(TypeMirror other) {
    return type.isSubtypeOf((other as EngineTypeMirror).type);
  }

  // TODO: implement originalDeclaration
  @override
  TypeMirror get originalDeclaration => null;

  @override
  Type get reflectedType => throw new UnsupportedError("No dynamic evaluation");

  // TODO: implement typeArguments
  @override
  List<TypeMirror> get typeArguments => null;

  // TODO: implement typeVariables
  @override
  List<TypeVariableMirror> get typeVariables => null;
}

class EngineSourceLocation implements SourceLocation {
  Element element;

  EngineSourceLocation(this.element);

  @override
  int get column {
    Source source = element.source;
    if (source == null) {
      return 0;
    }
    LineInfo lineInfo = element.context.getLineInfo(source);
    if (lineInfo == null) {
      return 0;
    }
    LineInfo_Location location = lineInfo.getLocation(element.nameOffset);
    if (location == null) {
      return 0;
    }
    return location.columnNumber;
  }

  @override
  int get line {
    Source source = element.source;
    if (source == null) {
      return 0;
    }
    LineInfo lineInfo = element.context.getLineInfo(source);
    if (lineInfo == null) {
      return 0;
    }
    LineInfo_Location location = lineInfo.getLocation(element.nameOffset);
    if (location == null) {
      return 0;
    }
    return location.lineNumber;
  }

  // TODO: implement sourceUri
  @override
  Uri get sourceUri => null; //element.source.uri;
}
