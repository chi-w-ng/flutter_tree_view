import 'package:flutter/widgets.dart';

import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';

enum ExpansionButtonType { folderFile, chevron }

class AppController with ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static AppController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppControllerScope>()!
        .controller;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final rootNode = TreeNode(id: 0);
    generateSampleTree(rootNode);

    treeController = TreeViewController(
      rootNode: rootNode,
    );

    _isInitialized = true;
  }

  //* == == == == == TreeView == == == == ==

  late final Map<int, bool> _selectedNodes = {};

  bool isSelected(int id) => _selectedNodes[id] ?? false;

  void toggleSelection(int id, [bool? shouldSelect]) {
    shouldSelect ??= !isSelected(id);
    shouldSelect ? _select(id) : _deselect(id);

    notifyListeners();
  }

  void _select(int id) => _selectedNodes[id] = true;
  void _deselect(int id) => _selectedNodes.remove(id);

  void selectAll([bool select = true]) {
    if (select) {
      rootNode.descendants.forEach(
        (descendant) => _selectedNodes[descendant.id] = true,
      );
    } else {
      rootNode.descendants.forEach(
        (descendant) => _selectedNodes.remove(descendant.id),
      );
    }
    notifyListeners();
  }

  TreeNode get rootNode => treeController.rootNode;

  late final TreeViewController treeController;

  //* == == == == == Scroll == == == == ==

  final nodeHeight = 40.0;

  late final scrollController = ScrollController();

  void scrollTo(TreeNode node) {
    final nodeToScroll = node.parent == rootNode ? node : node.parent ?? node;
    final offset = treeController.indexOf(nodeToScroll) * nodeHeight;

    scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  //* == == == == == General == == == == ==

  final treeViewTheme = ValueNotifier(const TreeViewTheme());
  final expansionButtonType = ValueNotifier(ExpansionButtonType.folderFile);

  void updateTheme(TreeViewTheme theme) {
    treeViewTheme.value = theme;
  }

  void updateExpansionButton(ExpansionButtonType type) {
    expansionButtonType.value = type;
  }

  @override
  void dispose() {
    treeController.dispose();
    scrollController.dispose();

    treeViewTheme.dispose();
    expansionButtonType.dispose();
    super.dispose();
  }
}

class AppControllerScope extends InheritedWidget {
  const AppControllerScope({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final AppController controller;

  @override
  bool updateShouldNotify(AppControllerScope oldWidget) => false;
}

int currentNodeId = 0;
void generateSampleTree(TreeNode parent) {
  final depth = parent.depth;
  if (depth >= depthLimit) {
    return;
  }
  for (final alph in alphebet) {
    parent.addChild(
        TreeNode(id: ++currentNodeId, label: '$alph$currentNodeId$depth'));
  }
  parent.children.forEach(generateSampleTree);
}

const depthLimit = 3;
const alphebet = <String>[
  'A',
  'B',
  'C',
  'D',
  'E',
  // 'F',
  // 'G',
  // 'H',
  // 'I',
  // 'J',
  // 'K',
  // 'L',
  // 'M',
  // 'N',
  // 'O',
  // 'P',
  // 'Q',
  // 'R',
  // 'S',
  // 'T',
  // 'U',
  // 'V',
  // 'W',
  // 'X',
  // 'Y',
  // 'Z'
];
