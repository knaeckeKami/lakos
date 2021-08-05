import 'package:directed_graph/directed_graph.dart';
import 'package:test/test.dart';
import 'package:lakos/src/all_cycles.dart';

void main() {
  test('empty graph does not have cycles', () {
    final graph = DirectedGraph<Object>({});

    expect(graph.allCycles(), isEmpty);
  });

  test('trival cycles are detected', () {
    final graph = DirectedGraph<String>({
      'a': {'a'}
    });

    expect(graph.allCycles(), [
      ['a', 'a']
    ]);
  });

  test('graph with no cycles return empty list', () {
    final graph = DirectedGraph<String>({
      'a': {'b','c'},
      'b': {'c'}
    });

    expect(graph.allCycles(), isEmpty);
  });


  test('graph with one cycle', () {
    final graph = DirectedGraph<String>({
      'a': {'b','c'},
      'b': {'c'},
      'c' : {'b'}
    });

    expect(graph.allCycles(), [['b', 'c', 'b']]);
  });

  test('graph with two cycles', () {
    final graph = DirectedGraph<String>({
      'a': {'b','c','d'},
      'b': {'c'},
      'c' : {'b'},
      'd' : {'a'}
    });

    expect(graph.allCycles(), [['b', 'c', 'b'], ['a','d','a']]);
  });

  test('graph with two cycles and trivial cycle', () {
    final graph = DirectedGraph<String>({
      'a': {'a','b','c','d'},
      'b': {'c'},
      'c' : {'b'},
      'd' : {'a'},

    });

    expect(graph.allCycles(), [['a', 'a'],['b', 'c', 'b'], ['a','d','a']]);
  });
}
