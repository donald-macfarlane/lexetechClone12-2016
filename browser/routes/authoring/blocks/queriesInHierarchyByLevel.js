module.exports = function(queries) {
  var rootNode = {n: 0, queries: []};
  var node = rootNode;
  var lastNode;
  var nodeStack = [node];
  var level = 1;

  function push(n) {
    if (!node.queries) {
      node.queries = [];
    }

    node.queries.push(n);
  }

  var n = 1;

  function createNode(query) {
    var node = {};
    if (query) {
      node.query = query;
    }

    return node;
  }

  function up(query) {
    level++;

    if (!lastNode) {
      lastNode = createNode();
      push(lastNode);
    }

    node = lastNode;
    nodeStack.push(node);
    lastNode = undefined;
  }

  function down() {
    level--;
    lastNode = undefined;
    nodeStack.pop();
    node = nodeStack[nodeStack.length - 1];
  }

  function same(query) {
    lastNode = createNode(query);
    push(lastNode);
  }

  queries.forEach(function (query) {
    while (level != query.level) {
      if (query.level > level) {
        up(query);
      } else if (query.level < level) {
        down();
      }
    }

    same(query);
  });

  return rootNode.queries;
};
