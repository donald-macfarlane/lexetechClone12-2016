var h = require('plastiq').html;
var _ = require('underscore');
var Promise = require('bluebird');
var http = require('./http');
var lexemeApi = require('./lexemeApi');
var prototype = require('prote');

var api = lexemeApi();

var debugComponent = prototype({
  constructor: function (model) {
    var self = this;
    self.model = model;
  },

  refresh: function () {},

  loadBlocks: function () {
    var self = this;
    var query = self.model.currentQuery();

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

      http.get('/api/predicants').then(function (predicants) {
        self.predicants = predicants;
        self.refresh();
      });
    }
  },

  render: function () {
    var predicants = this.predicants;
    var query = this.model.currentQuery();

    this.refresh = h.refresh;

    if (this.show) {
      if (query) {
        var context = query.context;
        var previousContext = query.previousContext;
        var nextContext = query.nextContext;

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

        function join(array, dom) {
          var result = [];

          for(var n = 0; n < array.length; n++) {
            if (n !== 0) {
              result.push(dom);
            }
            result.push(array[n]);
          }

          return result;
        }

        function contextPredicants(context) {
          return Object.keys(context.predicants).map(function (p) {
            return predicants[p].name;
          });
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

        return h('.query-detail',
          h('div',
            h('p', 'coherence index: ', renderContextScalars(previousContext, context, 'coherenceIndex', code)),
            h('p', 'level: ', renderContextScalars(previousContext, context, 'level', code)),
            self.predicants
              ? h('p', 'predicants: ', renderContextArrays(previousContext, context, contextPredicants, code))
              : undefined,
            h('p', 'blocks: ', renderContextArrays(previousContext, context, contextBlocks, code))
          ),
          h('ol.blocks',
            query.loadedBlocks
              ? query.loadedBlocks.map(function (block) {
                  return h('li.block',
                    h('h3', 'Block ', renderBlockName(block)),
                    h('ol.block-queries',
                      block.queries.map(function (q, index) {
                        var previous = compareWithContext(block.id, index, previousContext);
                        var current = compareWithContext(block.id, index, context);
                        var next = query.query
                          ? compareWithContext(block.id, index, nextContext)
                          : -1;

                        return h('li.block-query',
                          {
                            class: {
                              before: current < 0,
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
        );
      }
    }
  }
});

module.exports = debugComponent;
