var Promise = require("bluebird");
var _ = require("underscore");
var createContext = require("./context");
var createCache = require("../common/cache");
var lexemeApi = require("../browser/lexemeApi");

function cloneContext(c) {
  var predicants, blockStack;
  predicants = {};
  Object.keys(c.predicants).forEach(function(pk) {
    return predicants[pk] = c.predicants[pk];
  });
  blockStack = JSON.parse(JSON.stringify(c.blockStack));
  return createContext({
    coherenceIndex: c.coherenceIndex,
    block: c.block,
    blocks: c.blocks.slice(0),
    level: c.level,
    predicants: predicants,
    blockStack: blockStack,
    loopPredicants: JSON.parse(JSON.stringify(c.loopPredicants)),
    history: JSON.parse(JSON.stringify(c.history))
  });
}

var actions = {
  none: function(query, response, context) {},

  email: function(query, response, context) {},

  addBlocks: function(query, response, context) {
    var blocks = Array.prototype.slice.call(arguments, 3, arguments.length);

    context.pushBlockStack();
    context.coherenceIndex = 0;
    context.block = blocks.shift();

    context.blocks = blocks;
  },

  setBlocks: function(query, response, context) {
    var blocks = Array.prototype.slice.call(arguments, 3, arguments.length);

    var nextBlock;
    context.blocks = blocks.slice(0);
    nextBlock = context.blocks.shift();

    if (String(nextBlock) !== String(context.block)) {
      context.block = nextBlock;
      context.coherenceIndex = 0;
    }
  },

  setVariable: function(query, response, context, variable, value) {},

  repeatLexeme: function(query, response, context) {
    --context.coherenceIndex;
    response.repeating = true;
  },

  loopBack: function(query, response, context) {
    var queryLevel = context.level;
    var loopHead = findLoopHead(context, queryLevel);

    context.coherenceIndex = loopHead.loopHead.index;

    context.parkLoopPredicants(queryLevel, loopHead.index);
  }
};

function findLoopHead(context, queryLevel) {
  for(var n = context.history.length - 1; n >= 0; n--) {
    var historyItem = context.history[n];

    if (historyItem.level < queryLevel) {
      return {index: n, loopHead: historyItem};
    }
  }

  throw new Error('could not find loop head');
}

function newContextFromResponseContext(query, response, context) {
  var newContext = cloneContext(context);
  newContext.level = response.setLevel;
  ++newContext.coherenceIndex;

  if (response.actions) {
    response.actions.forEach(function (responseAction) {
      var action = actions[responseAction.name];
      action.apply(null, [query, response, newContext].concat(responseAction.arguments));
    });
  }

  response.predicants.forEach(function (p) {
    newContext.predicants[p] = newContext.history.length - 1;
  });

  return newContext;
}

function anyPredicantInFoundIn(predicants, currentPredicants) {
  if (predicants.length > 0) {
    return _.any(predicants, function(p) {
      return currentPredicants[p] !== undefined;
    });
  } else {
    return true;
  }
}

function blockInActiveBlocks(block, blocks) {
  return blocks[block];
}

function findNextQuery(api, context) {
  var blocksSearched = [];

  function findNext(context) {
    blocksSearched.push(context.block);

    return findNextQueryInCurrentBlock(api, context).then(function(query) {
      if (!query) {
        if (context.blocks.length > 0) {
          context.block = context.blocks.shift();
          context.coherenceIndex = 0;
          return findNext(context);
        } else if (context.blockStack.length > 0) {
          context.popBlockStack();
          return findNext(context);
        }
      } else {
        return query;
      }
    });
  }

  var result = {};

  return findNext(context).then(function(q) {
    result.query = q;
    result.blocksSearched = blocksSearched;
    return result;
  });
}

function findNextQueryInCurrentBlock(api, context) {
  return findNextItemInStartingFromMatching(api.block(context.block), context.coherenceIndex, function(query) {
    return query.level <= context.level && anyPredicantInFoundIn(query.predicants, context.predicants);
  });
}

function preloadQueryGraph(query, depth) {
  if (depth > 0 && query.query) {
    Promise.all(query.responses.map(function (r) {
      return r.query({preload: false}).then(function (q) {
        return preloadQueryGraph(q, depth - 1);
      });
    }));
  }
}

var nocache = {
  cacheBy: function(key, fn) {
    return fn();
  }
};

module.exports = function(options) {
  var api = (options && options.hasOwnProperty('api'))? options.api: lexemeApi();
  var cache = (options && options.hasOwnProperty('cache'))? options.cache: true;
  var hack = (options && options.hasOwnProperty('hack'))? options.hack: false;

  var queryCache = cache && createCache() || nocache;

  function queryGraph(next, context) {
    var graph = {
      query: next.query,
      context: next.context,
      previousContext: next.previousContext,
      startingContext: next.startingContext,
      blocksSearched: next.blocksSearched,

      omit: function () {
        return nextQueryForOmit(context);
      },

      skip: function () {
        return nextQueryForSkip(next.query, context);
      }
    };

    if (next.query) {
      graph.responses = next.query.responses.map(function (r) {
        return {
          id: r.id,
          text: r.text,
          styles: r.styles || {style1: '', style2: ''},
          repeat: r.actions.filter(function (x) { return x.name == 'repeatLexeme'; }).length > 0,
          variables: r.actions.filter(function (x) { return x.name == 'setVariable'; }).map(function (action) {
            return {name: action.arguments[0], value: action.arguments[1]};
          }),

          query: function(options) {
            var self = this;

            var preload = (options && options.hasOwnProperty('preload'))? options.preload: true;

            if (!cache) {
              return nextQueryForResponse(next.query, r, context);
            } else {
              if (!self._query) {
                self._query = nextQueryForResponse(next.query, r, context);
              }

              if (preload && !self.preloaded) {
                self.preloaded = true;

                self._query.then(function(query) {
                  preloadQueryGraph(query, 4);
                });
              }

              return self._query;
            }
          }
        };
      });
    }

    return graph;
  }

  function nextQueryForResponse(query, response, context) {
    var newContext = newContextFromResponseContext(query, response, context);
    return nextQueryForContext(newContext, context);
  }

  function nextQueryForOmit(context) {
    var newContext = cloneContext(context);
    newContext.coherenceIndex++;
    return nextQueryForContext(newContext, context);
  }

  function nextQueryForSkip(query, context) {
    var newContext = cloneContext(context);
    newContext.coherenceIndex++;
    newContext.level = query.level;
    return nextQueryForContext(newContext, context);
  }

  function nextQueryForContext(context, previousContext) {
    return queryCache.cacheBy(context.coherenceIndex + ":" + context.key(), function() {
      var originalContext = cloneContext(context);

      return findNextQuery(api, context).then(function(query) {
        if (query.query) {
          context.coherenceIndex = query.query.index;
          context.history.push({level: query.query.level, index: query.query.index});
          context.restoreLoopPredicants(query.query.level);
        }

        query.previousContext = previousContext;
        query.startingContext = originalContext;
        query.context = context;

        return queryGraph(query, context);
      });
    });
  }

  function hackPredicants() {
    return api.predicants().then(function (predicants) {
      var predicantsByName = _.indexBy(_.values(predicants), 'name');
      return ['H&P', 'HemOnc'].map(function (name) {
        return predicantsByName[name];
      }).filter(function (pred) {
        return pred;
      }).map(function (pred) {
        return pred.id;
      });
    });
  }

  return {
    firstQueryGraph: function() {
      var hackpredsPromise = hackPredicants();

      return api.block(1).query(0).then(function(query) {
        function makeGraph(hackpreds) {
          var firstPredicants = {};

          if (hack) {
            hackpreds.concat(query.predicants).forEach(function(p) {
              return firstPredicants[p] = true;
            });
          }

          var context = createContext({
            coherenceIndex: 0,
            block: query.block,
            blocks: hack? _.range(2, 19).map(String): [],
            level: 1,
            predicants: firstPredicants,
            blockStack: [],
            history: [{level: query.level, index: 0}],
            loopPredicants: []
          });

          var graph = queryGraph({
            query: query,
            context: context,
            startingContext: context
          }, context);

          if (cache) {
            preloadQueryGraph(graph, 4);
          }

          return graph;
        }

        if (hack) {
          return hackpredsPromise.then(makeGraph);
        } else {
          return makeGraph();
        }
      });
    },

    query: function(queryId, context) {
      return api.query(queryId).then(function (query) {
        return queryGraph({
          query: query,
          context: context,
          startingContext: context
        }, context);
      });
    }
  };
};

function findNextItemInStartingFromMatching(block, index, predicate) {
  return block.length().then(function(blockLength) {
    if (index < blockLength) {
      return block.query(index).then(function(item) {
        if (predicate(item)) {
          item.index = index;
          return item;
        } else {
          return findNextItemInStartingFromMatching(block, index + 1, predicate);
        }
      });
    }
  });
}
