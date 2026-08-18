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
    _insert(root, RTreeEntry<T>(box, item));
    root.updateBoundingBox();
  }

  void _insert(RTreeNode<T> node, RTreeEntry<T> entry) {
    if (node.isLeaf) {
      node.entries.add(entry);
    } else {
      // Find best child (simplest: least enlargement)
      RTreeNode<T>? bestChild;
      double minEnlargement = double.infinity;

      for (var child in node.children) {
        final currentBox = child.boundingBox ?? entry.box;
        final enlargedBox = currentBox.expandToInclude(entry.box);
        final enlargement = enlargedBox.area() - currentBox.area();

        if (enlargement < minEnlargement) {
          minEnlargement = enlargement;
          bestChild = child;
        }
      }

      if (bestChild != null) {
        _insert(bestChild, entry);
        bestChild.updateBoundingBox();
      } else if (node.children.isEmpty) {
        final newChild = RTreeNode<T>(true);
        newChild.entries.add(entry);
        newChild.updateBoundingBox();
        node.children.add(newChild);
      }
    }
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
