import 'geometry.dart';

class RTreeEntry<T> {
  final BoundingBox2D box;
  final T item;

  RTreeEntry(this.box, this.item);
}

class RTreeNode<T> {
  final bool isLeaf;
  final List<RTreeEntry<T>> entries = [];
  final List<RTreeNode<T>> children = [];
  BoundingBox2D? boundingBox;

  RTreeNode(this.isLeaf);

  void updateBoundingBox() {
    if (isLeaf) {
      if (entries.isEmpty) {
        boundingBox = null;
        return;
      }
      var box = entries.first.box;
      for (int i = 1; i < entries.length; i++) {
        box = box.expandToInclude(entries[i].box);
      }
      boundingBox = box;
    } else {
      if (children.isEmpty) {
        boundingBox = null;
        return;
      }
      var box = children.first.boundingBox;
      if (box == null) return;
      for (int i = 1; i < children.length; i++) {
        final childBox = children[i].boundingBox;
        if (childBox != null) {
          box = box!.expandToInclude(childBox);
        }
      }
      boundingBox = box;
    }
  }
}

class RTreeIndex<T> {
  final int maxChildren;
  RTreeNode<T> root;

  RTreeIndex({this.maxChildren = 4}) : root = RTreeNode<T>(true);

  void insert(BoundingBox2D box, T item) {
    final splitNode = _insert(root, RTreeEntry<T>(box, item));
    root.updateBoundingBox();
    if (splitNode != null) {
      final newRoot = RTreeNode<T>(false);
      newRoot.children.add(root);
      newRoot.children.add(splitNode);
      newRoot.updateBoundingBox();
      root = newRoot;
    }
  }

  RTreeNode<T>? _insert(RTreeNode<T> node, RTreeEntry<T> entry) {
    if (node.isLeaf) {
      node.entries.add(entry);
      node.updateBoundingBox();
      if (node.entries.length > maxChildren) {
        return _splitLeaf(node);
      }
      return null;
    } else {
      // Find best child (simplest: least enlargement)
      RTreeNode<T>? bestChild;
      double minEnlargement = double.infinity;
      double bestArea = double.infinity;

      for (var child in node.children) {
        final currentBox = child.boundingBox ?? entry.box;
        final enlargedBox = currentBox.expandToInclude(entry.box);
        final currentArea = currentBox.area();
        final enlargement = enlargedBox.area() - currentArea;

        if (enlargement < minEnlargement ||
            (enlargement == minEnlargement && currentArea < bestArea)) {
          minEnlargement = enlargement;
          bestArea = currentArea;
          bestChild = child;
        }
      }

      if (bestChild == null) {
        final newChild = RTreeNode<T>(true);
        newChild.entries.add(entry);
        newChild.updateBoundingBox();
        node.children.add(newChild);
        node.updateBoundingBox();
        return null;
      }

      final splitChild = _insert(bestChild, entry);
      bestChild.updateBoundingBox();
      if (splitChild != null) {
        splitChild.updateBoundingBox();
        node.children.add(splitChild);
        node.updateBoundingBox();
        if (node.children.length > maxChildren) {
          return _splitInternal(node);
        }
      }
      node.updateBoundingBox();
      return null;
    }
  }

  RTreeNode<T> _splitLeaf(RTreeNode<T> node) {
    final parts = _partition<RTreeEntry<T>>(node.entries, (e) => e.box);
    node.entries
      ..clear()
      ..addAll(parts[0]);
    node.updateBoundingBox();

    final sibling = RTreeNode<T>(true);
    sibling.entries.addAll(parts[1]);
    sibling.updateBoundingBox();
    return sibling;
  }

  RTreeNode<T> _splitInternal(RTreeNode<T> node) {
    final parts = _partition<RTreeNode<T>>(
      node.children,
      (c) => c.boundingBox ?? const BoundingBox2D(0, 0, 0, 0),
    );
    node.children
      ..clear()
      ..addAll(parts[0]);
    node.updateBoundingBox();

    final sibling = RTreeNode<T>(false);
    sibling.children.addAll(parts[1]);
    sibling.updateBoundingBox();
    return sibling;
  }

  List<List<E>> _partition<E>(List<E> items, BoundingBox2D Function(E) getBox) {
    final n = items.length;
    final minCount = (maxChildren / 2).ceil().clamp(1, maxChildren);

    List<E> bestA = [];
    List<E> bestB = [];
    double bestArea = double.infinity;

    void evaluatePartition(List<E> a, List<E> b) {
      if (a.length < minCount || b.length < minCount) return;
      var boxA = getBox(a.first);
      for (int i = 1; i < a.length; i++) {
        boxA = boxA.expandToInclude(getBox(a[i]));
      }
      var boxB = getBox(b.first);
      for (int i = 1; i < b.length; i++) {
        boxB = boxB.expandToInclude(getBox(b[i]));
      }
      final area = boxA.area() + boxB.area();
      if (area < bestArea) {
        bestArea = area;
        bestA = List.from(a);
        bestB = List.from(b);
      }
    }

    if (n <= 10) {
      final totalCombos = 1 << n;
      for (int mask = 1; mask < totalCombos - 1; mask++) {
        final a = <E>[];
        final b = <E>[];
        for (int i = 0; i < n; i++) {
          if ((mask & (1 << i)) != 0) {
            a.add(items[i]);
          } else {
            b.add(items[i]);
          }
        }
        evaluatePartition(a, b);
      }
    } else {
      for (final comparator in [
        (E e1, E e2) => getBox(e1).minX.compareTo(getBox(e2).minX),
        (E e1, E e2) => getBox(e1).maxX.compareTo(getBox(e2).maxX),
        (E e1, E e2) => getBox(e1).minY.compareTo(getBox(e2).minY),
        (E e1, E e2) => getBox(e1).maxY.compareTo(getBox(e2).maxY),
      ]) {
        final sorted = List<E>.from(items)..sort(comparator);
        for (int i = minCount; i <= n - minCount; i++) {
          evaluatePartition(sorted.sublist(0, i), sorted.sublist(i));
        }
      }
    }

    if (bestA.isEmpty || bestB.isEmpty) {
      final mid = n ~/ 2;
      bestA = items.sublist(0, mid);
      bestB = items.sublist(mid);
    }

    return [bestA, bestB];
  }

  List<T> search(BoundingBox2D queryBox) {
    final results = <T>[];
    _search(root, queryBox, results);
    return results;
  }

  void _search(RTreeNode<T> node, BoundingBox2D queryBox, List<T> results) {
    if (node.boundingBox != null && !node.boundingBox!.intersects(queryBox)) {
      return;
    }

    if (node.isLeaf) {
      for (var entry in node.entries) {
        if (entry.box.intersects(queryBox)) {
          results.add(entry.item);
        }
      }
    } else {
      for (var child in node.children) {
        _search(child, queryBox, results);
      }
    }
  }
}
