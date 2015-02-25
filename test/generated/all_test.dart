library engine.test;

import "ast_test.dart" as t_ast;
import "element_test.dart" as t_element;
import "parser_test.dart" as t_parser;
import "resolver_test.dart" as t_resolver;
import "scanner_test.dart" as t_scanner;

main() {
  t_ast.main();
  t_element.main();
  t_parser.main();
  t_resolver.main();
  t_scanner.main();
}
