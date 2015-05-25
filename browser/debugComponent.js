var h = require('plastiq').html;
var _ = require('underscore');
var Promise = require('bluebird');
var lexemeApi = require('./lexemeApi');
var prototype = require('prote');
var renderJson = require('./renderJson');
var join = require('./join');

var api = lexemeApi();

var debugComponent = prototype({
  constructor: function (options) {
    this.currentQuery = options.currentQuery;
    this.lexemeApi = options.lexemeApi;
    this.selectedResponse = options.selectedResponse;
    this.variables = options.variables;
  },

  refresh: function () {},

  loadBlocks: function () {
    var self = this;
    var query = self.currentQuery();

    if (!query.loadedBlocks && query.blocksSearched) {
      return Promise.map(query.blocksSearched.map(function (blockId) {
        return {
          id: blockId,
          block: api.block(blockId)
        };
      }), function (block) {
        return block.block.length().then(function (length) {
          var queryIndices = _.range(length);

          return Promise.map(queryIndices, function (index) {
            return block.block.query(index);
          }).then(function (queries) {
            return {
              id: block.id,
              queries: queries
            };
          });
        });
      }).then(function (blockQueries) {
        query.loadedBlocks = blockQueries;
        self.refresh();
      });
    }
  },

  loadPredicants: function () {
    if (!this.predicants) {
      var self = this;

      this.lexemeApi.predicants().then(function (predicants) {
        self.predicants = predicants;
        self.refresh();
      });
    }
  },

  renderQuery: function (query) {
    var self = this;
    var startingContext = query.startingContext;
    var context = query.context;
    var previousContext = query.previousContext;

    this.loadBlocks();
    this.loadPredicants();

    function compare(x, y) {
      if (x < y) {
        return -1;
      } else if (x > y) {
        return 1;
      } else {
        return 0;
      }
    }

    function compareWithContext(blockId, queryIndex, context) {
      var contextBlockIndex = query.blocksSearched.indexOf(context.block);
      var blockIndex = query.blocksSearched.indexOf(blockId);
      var c = compare(blockIndex, contextBlockIndex);

      if (c == 0) {
        return compare(queryIndex, context.coherenceIndex);
      } else {
        return c;
      }
    }

    function predicantNames(predicants) {
      return Object.keys(predicants).map(function (p) {
        return self.predicants[p].name;
      });
    }

    function contextPredicants(context) {
      return predicantNames(context.predicants);
    }

    function contextBlocks(context) {
      return [context.block].concat(context.blocks);
    }

    function renderBlockName(block) {
      if (block.name) {
        return block.id + ': ' + block.name;
      } else {
        return block.id;
      }
    }

    function renderContextScalars(before, after, property, render) {
      if(before) {
        if (before[property] == after[property]) {
          return render(after[property]);
        } else {
          return [render(before[property]), ' => ', render(after[property])];
        }
      } else {
        return render(after[property]);
      }
    }

    function renderContextArrays(before, after, getArray, render) {
      if(before) {
        var beforeArray = getArray(before);
        var afterArray = getArray(after);

        if (beforeArray.join(',') == afterArray.join(',')) {
          return join(beforeArray.map(render), ', ');
        } else {
          return [join(beforeArray.map(render), ', '), ' => ', join(afterArray.map(render), ', ')];
        }
      } else {
        return join(getArray(after).map(render), ', ');
      }
    }

    function code(x) {
      return h('code', x);
    }

    function loopPredicants(context) {
      var predicants = [];
      for (var n = 0; n < context.loopPredicants.length; n++) {
        predicants.push(context.loopPredicants[n]);
      }
      return predicants;
    }

    function renderAction(action) {
      return h('span', action.name, '(', join(action.arguments.map(code), ', '), ')');
    }

    function renderActions(response) {
      var actions = response.actions.filter(function (a) { return a.name !== 'none'; });

      return [
        h('h4', 'actions'),
        h('ul.actions', actions.map(function (a) {
          return h('li', renderAction(a));
        }))
      ];
    }

    function renderLoopPredicants(context) {
      if (context.loopPredicants.length) {
        return [
          h('h3', 'loop predicants'),
          h('ol',
            context.loopPredicants.map(function (loopPredicant) {
              return h('li',
                loopPredicant
                  ? code(predicantNames(loopPredicant).join(', '))
                  : '(none)'
              );
            })
          )
        ];
      }
    }

    function renderResponse(response) {
      if (response) {
        return [
          h('h3', 'response'),
          renderActions(response)
        ];
      }
    }

    function renderVariables() {
      var variables = self.variables();

      if (variables.length) {
        return [
          h('h3', 'variables'),
          h('ol',
            variables.map(function (variable) {
              return h('li', code(variable.name), ' = ', variable.value);
            })
          )
        ];
      }
    }

    var selectedResponse = this.selectedResponse();

    return [
      h('div',
        h('p', 'coherence index: ', renderContextScalars(previousContext, context, 'coherenceIndex', code)),
        h('p', 'level: ', renderContextScalars(previousContext, context, 'level', code)),
        this.predicants
          ? h('p', 'predicants: ', renderContextArrays(previousContext, context, contextPredicants, code))
          : undefined,
        h('p', 'blocks: ', renderContextArrays(previousContext, context, contextBlocks, code)),
        renderVariables(),
        renderLoopPredicants(context),
        renderResponse(selectedResponse)
      ),
      h('.context', renderJson(context)),
      h('ol.blocks',
        query.loadedBlocks
          ? query.loadedBlocks.map(function (block) {
              return h('li.block',
                h('h3', 'Block ', renderBlockName(block)),
                h('ol.block-queries', {start: '0'},
                  block.queries.map(function (q, index) {
                    var previous = compareWithContext(block.id, index, previousContext);
                    var current = compareWithContext(block.id, index, startingContext);
                    var next = query.query
                      ? compareWithContext(block.id, index, context)
                      : -1;

                    return h('li.block-query',
                      {
                        class: {
                          before: current < 0 && previous != 0,
                          previous: previous == 0,
                          skipped: current >= 0 && next < 0,
                          after: next > 0,
                          found: next == 0
                        }
                      },
                      h('span', {style: {'padding-left': ((q.level - 1) * 10) + 'px'}}, q.name, ' (', q.level, ')')
                    );
                  })
                )
              )
            })
          : undefined
      )
    ];
  },

  render: function () {
    var self = this;
    var query = this.currentQuery();

    this.refresh = h.refresh;

    return query? h('.debug',
      self.renderQuery(query)
    ): undefined;
  }
});

module.exports = debugComponent;
