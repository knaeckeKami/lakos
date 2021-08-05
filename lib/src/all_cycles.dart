import 'package:directed_graph/directed_graph.dart';

extension AllCycles<T extends Object> on DirectedGraph<T> {

  /// compute all cycles of this graph
  List<List<T>> allCycles() {
    final cycles = <List<T>>[];
    // optimization: if graph is acyclic, do nothing
    if (isAcyclic) {
      return cycles;
    }

    //copy the graph to be able to mutate it freely
    final mutableCopy = DirectedGraph.of(this);

    while (!mutableCopy.isAcyclic) {
      final cycle = mutableCopy.cycle;
      assert(cycle.isNotEmpty);
      //add the found cycle the the list of cycles
      cycles.add(cycle);
      // now we remove the circle from the graph to find the rest of the cycles

      //edge case: trivial cycles like A->A
      if (cycle.length < 2) {
        mutableCopy.removeEdges(cycle.first, {cycle.first});
      } else {
        //just remove the last part of the cycle, e.g
        // A->B->C->A => A->B->C
        final length = cycle.length;
        mutableCopy.removeEdges(cycle[length - 2], {cycle.first});
      }
      //now search for the next cycle
    }
    return cycles;
  }
}
