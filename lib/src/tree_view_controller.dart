import 'internal.dart';

/// Controller for managing the nodes that compose [TreeView].
///
/// This controller was extracted from [TreeView] for use cases where you
/// need to toggle/find a node from outside the [TreeView] widget subtree.
/// Makes it easy to pass the controller down the widget tree
/// through dependency injection (like the Provider package).
class TreeViewController {
  /// Creates a [TreeViewController].
  TreeViewController({
    required this.rootNode,
  }) : assert(rootNode.isRoot, "The rootNode's parent must be null.");

  /// The [TreeNode] that will store all top level nodes.
  final TreeNode rootNode;

  // * ~~~~~~~~~~ MANAGE NODES ~~~~~~~~~~ *

  /// The list of nodes that are currently visible in the [TreeView].
  List<TreeNode> get visibleNodes => _visibleNodes;
  late final List<TreeNode> _visibleNodes;

  /// Returns the node at [index] of [visibleNodes].
  TreeNode nodeAt(int index) => _visibleNodes[index];

  /// Returns the index of [node] in [visibleNodes].
  int _indexOf(TreeNode node) => _visibleNodes.indexOf(node);

  void _insert(int index, TreeNode node) {
    _visibleNodes.insert(index, node);
    _expandCallback?.call(index);
  }

  void _insertAll(int index, List<TreeNode> nodes) {
    // The list must be reversed for the order to not get messed up
    nodes.reversed
        .where((node) => !_visibleNodes.contains(node))
        .forEach((node) => _insert(index, node));
  }

  void _removeAt(int index) {
    final removedNode = _visibleNodes.removeAt(index)
      ..removeExpansionCallback();

    _collapseCallback?.call(index, removedNode);
  }

  void _removeAll(List<TreeNode> nodes) {
    nodes
        .where(_visibleNodes.contains)
        .forEach((node) => _removeAt(_indexOf(node)));
  }

  // * ~~~~~~~~~~ EVENT RELATED ~~~~~~~~~~ *

  /// Used to notify the [TreeView] which index to animate when expanding.
  NodeExpandedCallback? _expandCallback;

  /// Used to notify the [TreeView] which index to animate when collapsing.
  NodeCollapsedCallback? _collapseCallback;

  // * ~~~~~~~~~~ EXPAND METHODS ~~~~~~~~~~ *

  /// Expands a single node.
  void expandNode(TreeNode node) {
    if (node.isLeaf || node.isExpanded) return;
    node.pExpand(); // Use private expand to avoid re-expanding.
    _insertAll(_indexOf(node) + 1, node.children);
  }

  /// Expands [node] and every descendant node.
  void expandSubtree(TreeNode node) {
    expandNode(node);
    node.children.forEach(expandSubtree);
  }

  /// Expands every node in the tree.
  void expandAll() => expandSubtree(rootNode);

  // * ~~~~~~~~~~ COLLAPSE METHODS ~~~~~~~~~~ *

  /// Collapses [node] and its subtree.
  void collapseNode(TreeNode node) {
    if (node.isLeaf || !node.isExpanded) return;
    node.pCollapse(); // Use private collapse to avoid re-collapsing.
    _removeAll(removableDescendantsOf(node));
  }

  /// Collapses all nodes.
  /// Only the children of [TreeView.rootNode] will be visible.
  void collapseAll() => collapseNode(rootNode);

  // * ~~~~~~~~~~ HELPER METHODS ~~~~~~~~~~ *

  /// Changes the `isSelected` property of [node] and its subtree
  /// to [state] (defaults to `true`).
  void selectSubtree(TreeNode node, [bool state = true]) {
    subtreeGenerator(node).forEach((n) => n.toggleSelected(state));
  }

  /// Changes the `isEnabled` property of [node] and its subtree
  /// to [state] (defaults to `true`).
  void enableSubtree(TreeNode node, [bool state = true]) {
    subtreeGenerator(node).forEach((n) => n.toggleEnabled(state));
  }

  /// Returns a list of every selected node in the subtree of [startingNode].
  ///
  /// If [startingNode] is null, starts from [rootNode].
  List<TreeNode> selectedNodes(TreeNode? startingNode) {
    return subtreeGenerator(startingNode ?? rootNode)
        .where((n) => n.isSelected)
        .toList(growable: false);
  }

  /// Returns a list of every enabled node in the subtree of [startingNode].
  ///
  /// If [startingNode] is null, starts from [rootNode].
  List<TreeNode> enabledNodes(TreeNode? startingNode) {
    return subtreeGenerator(startingNode ?? rootNode)
        .where((n) => n.isEnabled)
        .toList(growable: false);
  }

  // * ~~~~~~~~~~ OTHER METHODS ~~~~~~~~~~ *

  /// Returns a list with every node in the subtree of [node]
  /// that is removable (`depth > 0`), in post order. *(e.g. 3, 2, 1)*
  List<TreeNode> removableDescendantsOf(TreeNode node) {
    return reversedSubtreeGenerator(node)
        .where((node) => node.isRemovable)
        .toList(growable: false);
  }
}

/// Extension to hide internal functionality.
extension TreeViewControllerX on TreeViewController {
  void populateInitialNodes() {
    _visibleNodes = List<TreeNode>.from(rootNode.children);
  }

  /// Callback for expanding/collapsing nodes from its methods.
  void toggleNode(TreeNode node) {
    if (node.isExpanded) {
      _insertAll(_indexOf(node) + 1, node.children);
    } else {
      _removeAll(removableDescendantsOf(node));
    }
  }

  /// Sets the callback of `_expandCallback`.
  void addExpandCallback(NodeExpandedCallback cb) => _expandCallback = cb;

  /// Sets the callback of `_collapseCallback`.
  void addCollapseCallback(NodeCollapsedCallback cb) => _collapseCallback = cb;

  /// Sets both `_expandCallback` and `_collapseCallback` to `null`.
  void removeCallbacks() {
    _expandCallback = null;
    _collapseCallback = null;
  }
}
