var Promise = require("bluebird");
var _ = require("underscore");
var createContext = require("./context");
var createCache = require("../common/cache");
var lexemeApi = require("../browser/lexemeApi");

function cloneContext(c) {
    var predicants, blockStack;
    predicants = {};
    Object.keys(c.predicants).forEach(function(pk) {
        return predicants[pk] = true;
    });
    blockStack = JSON.parse(JSON.stringify(c.blockStack));
    return createContext({
        coherenceIndex: c.coherenceIndex,
        block: c.block,
        blocks: c.blocks.slice(0),
        level: c.level,
        predicants: predicants,
        blockStack: blockStack
    });
}

var actions = {
    none: function(response, context) {},

    email: function(response, context) {},

    addBlocks: function(response, context) {
      var blocks = Array.prototype.slice.call(arguments, 2, arguments.length);

      context.pushBlockStack();
      context.coherenceIndex = 0;
      context.block = blocks.shift();

      context.blocks = blocks;
    },

    setBlocks: function(response, context) {
      var blocks = Array.prototype.slice.call(arguments, 2, arguments.length);

      var nextBlock;
      context.blocks = blocks.slice(0);
      nextBlock = context.blocks.shift();

      if (String(nextBlock) !== String(context.block)) {
        context.block = nextBlock;
        context.coherenceIndex = 0;
      }
    },

    setVariable: function(response, context, variable, value) {},

    repeatLexeme: function(response, context) {
      --context.coherenceIndex;
      response.repeating = true;
    },

    loopBack: function(response, context) {}
};

function newContextFromResponseContext(response, context) {
  var newContext = cloneContext(context);
  newContext.level = response.setLevel;
  ++newContext.coherenceIndex;

  if (response.actions) {
    response.actions.forEach(function (responseAction) {
      var action = actions[responseAction.name];
      action.apply(null, [response, newContext].concat(responseAction.arguments));
    });
  }

  response.predicants.forEach(function (p) {
    newContext.predicants[p] = true;
  });

  return newContext;
}

function anyPredicantInFoundIn(predicants, currentPredicants) {
  if (predicants.length > 0) {
    return _.any(predicants, function(p) {
      return currentPredicants[p];
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

  var queryCache = cache && createCache() || nocache;

  function queryGraph(next, context) {
    var graph = {
      query: next.query,
      context: next.context,
      previousContext: next.previousContext,
      nextContext: next.nextContext,
      blocksSearched: next.blocksSearched
    };

    if (next.query) {
      graph.responses = next.query.responses.map(function (r) {
        return {
          id: r.id,
          text: r.text,
          styles: r.styles || {style1: '', style2: ''},
          repeat: r.actions.filter(function (x) { return x.name == 'repeatLexeme'; }).length > 0,

          query: function(options) {
            var self = this;

            var preload = (options && options.hasOwnProperty('preload'))? options.preload: true;

            if (!cache) {
              return nextQueryForResponse(r, context);
            } else {
              if (!self._query) {
                self._query = nextQueryForResponse(r, context);
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

  function nextQueryForResponse(response, context) {
    var newContext = newContextFromResponseContext(response, context);

    return queryCache.cacheBy(newContext.coherenceIndex + ":" + newContext.key(), function() {
      var originalContext = cloneContext(newContext);

      return findNextQuery(api, newContext).then(function(next) {
        if (next.query) {
          newContext.coherenceIndex = next.query.index;
        }

        next.previousContext = context;
        next.context = originalContext;
        next.nextContext = newContext;

        return queryGraph(next, newContext);
      });
    });
  }

  return {
    firstQueryGraph: function() {
      var predicantsPromise = api.predicants();

      return api.block(1).query(0).then(function(query) {
        return predicantsPromise.then(function (predicants) {
          var predicantsByName = _.indexBy(_.values(predicants), 'name');

          var firstPredicants = {};

          [predicantsByName['H&P'].id, predicantsByName['HemOnc'].id].concat(query.predicants).forEach(function(p) {
            return firstPredicants[p] = true;
          });

          var context = createContext({
            coherenceIndex: 0,
            block: query.block,
            blocks: _.range(2, 19).map(String),
            level: 1,
            predicants: firstPredicants,
            blockStack: []
          });

          var graph = queryGraph({
            query: query,
            context: context,
            nextContext: context
          }, context);

          if (cache) {
            preloadQueryGraph(graph, 4);
          }

          return graph;
        });
      });
    },

    query: function(queryId, context) {
      return api.query(queryId).then(function (query) {
        return queryGraph({
          query: query,
          context: context,
          nextContext: context
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
