var prototype = require('prote');
var self = this;
var cache = require("../common/cache");
var _ = require("underscore");
var bluebird = require("bluebird");
var semaphore = require("./semaphore");
var redisClient = require('./redisClient');

module.exports = function() {
  var self = this;
  var client = redisClient({promises: true});
  var oneMax = semaphore();

  function setMax(key, value) {
    return oneMax(function() {
      return client.watch(key).then(function() {
        return client.get(key).then(function(existingValue) {
          var newValue = Math.max(existingValue, value);
          client.multi();
          client.set(key, newValue);
          return client.exec();
        });
      });
    });
  }

  function domainObject (name) {
    return {
      addAll: function(objects, options) {
        var keepIds = options && options.hasOwnProperty('keepIds')? options.keepIds: false;

        if (objects.length > 0) {
          function setIds() {
            if (keepIds) {
              var highest = _.max(objects.map(function (object) { return Number(object.id); }));
              return setMax("last_id:" + name, highest);
            } else {
              return client.incrby("last_id:" + name, objects.length).then(function(last) {
                var first = last - objects.length;
                var items = _.zip(objects, _.range(first + 1, last + 1));
                items.forEach(function (pn) {
                    pn[0].id = String(pn[1]);
                });
              });
            }
          }

          return setIds().then(function() {
            var keyValues = _.flatten(objects.map(function (p) {
              var key = name + ":" + p.id;
              var value = JSON.stringify(p);

              return [key, value];
            }), true);

            return client.mset.apply(client, keyValues);
          });
        } else {
          return Promise.resolve();
        }
      },

      get: function(id) {
        return client.get(name + ":" + id).then(function(object) {
          return JSON.parse(object);
        });
      },

      add: function(object) {
        return client.incr("last_id:" + name).then(function(lastId) {
          object.id = String(lastId);
          return client.set(name + ":" + object.id, JSON.stringify(object)).then(function() {
            return object;
          });
        });
      },

      update: function(id, object) {
        object.id = id;
        return client.set(name + ":" + id, JSON.stringify(object)).then(function() {
          return object;
        });
      },

      remove: function(id) {
        return client.del(name + ":" + id);
      },

      ids: function() {
        var ids = [];
        function scan(c) {
          var cursor =
            c === undefined
            ? 0
            : c === '0'
              ? undefined
              : c;

          if (cursor !== undefined) {
            return client.scan(cursor, "match", name + ":*").then(function(result) {
              ids.push.apply(ids, result[1]);
              return scan(result[0]);
            });
          }
        }

        return scan().then(function() {
          return ids;
        });
      },

      getAll: function(ids, options) {
        var withPrefix = options && options.hasOwnProperty('withPrefix')? options.withPrefix: false;

        var keys = withPrefix
          ? ids
          : ids.map(function (id) { return name + ":" + id; });

        if (keys.length > 0) {
          return client.mget(keys).then(function(values) {
            return values.map(function (value) {
              return JSON.parse(value);
            }).filter(function (object) {
              return !object.deleted;
            });
          });
        } else {
          return Promise.resolve([]);
        }
      },

      list: function() {
        var self = this;

        return self.ids().then(function(ids) {
          return self.getAll(ids, { withPrefix: true });
        });
      },

      removeAll: function() {
        return this.ids().then(function (ids) {
          if (ids.length) {
            return client.del.apply(client, ids);
          }
        });
      }
    };
  }

  var orderedListPrototype = prototype({
    add: function(id, item) {
      var self = this;

      return this.collection.add(item).then(function (i) {
        return client.rpush(self.name + ":" + id, i.id).then(function () {
          return i
        });
      });
    },

    addAll: function(id, items, options) {
      var self = this;

      if (items.length) {
        return this.collection.addAll(items, options).then(function () {
          var itemIds = items.map(function (item) { return item.id; });
          return client.rpush.apply(client, [self.name + ":" + id].concat(itemIds));
        });
      }
    },

    list: function(id) {
      var self = this;

      return client.lrange(this.name + ":" + id, 0, -1).then(function (ids) {
        return self.collection.getAll(ids);
      });
    },

    moveAfter: function(id, itemId, afterItemId) {
      client.multi();
      client.linsert(this.name + ":" + id, "after", afterItemId, itemId);
      client.lrem(this.name + ":" + id, 1, itemId);
      return client.exec();
    },

    moveBefore: function(id, itemId, beforeItemId) {
      client.multi();
      client.linsert(this.name + ":" + id, "before", beforeItemId, itemId);
      client.lrem(this.name + ":" + id, -1, itemId);
      return client.exec();
    },

    insertBefore: function(id, itemId, item) {
      var self = this;

      return self.collection.add(item).then(function(i) {
        return client.linsert(self.name + ":" + id, "before", itemId, i.id).then(function() {
          return i;
        });
      });
    },

    insertAfter: function(id, itemId, item) {
      var self = this;

      return self.collection.add(item).then(function(i) {
        return client.linsert(self.name + ":" + id, "after", itemId, i.id).then(function() {
          return i;
        });
      });
    },

    remove: function(id, itemId) {
      var self = this;
      return self.collection.remove(itemId).then(function() {
        return client.lrem(self.name + ":" + id, 1, itemId);
      });
    }
  });

  function orderedList(name, collection) {
    return orderedListPrototype({
      name: name,
      collection: collection
    });
  }

  var blocks = domainObject("block");
  var predicants = domainObject("predicant");
  var queries = domainObject("query");
  var blockQueries = orderedList("block_queries", queries);
  var userQueries = orderedList("user_queries", queries);

  return {
    clear: function() {
      return client.flushdb();
    },

    setLexicon: function(lexicon) {
      var self = this;

      return this.clear().then(function () {
        function writePredicants() {
          function allPredicantNames(blocks) {
            function queryPredicants(q) {
              var responsePredicants =
                q.responses
                  ? q.responses.map(function (r) {
                      return r.predicants;
                    })
                  : [];

              return q.predicants.concat(responsePredicants);
            }

            function blockPredicants(b) {
              return b.queries.map(queryPredicants);
            }

            var predicants = blocks.filter(function (b) {
              return b.queries;
            }).map(blockPredicants);

            return _.uniq(_.flatten(predicants));
          }

          var predicateNames = allPredicantNames(lexicon.blocks);

          var predicantObjects = predicateNames.map(function (name) {
            return { name: name };
          });

          return self.addPredicants(predicantObjects).then(function () {
            var predicantsByName = _.indexBy(predicantObjects, 'name');

            function mapPredicantNamesToIds(object) {
              object.predicants = object.predicants.map(function (pred) {
                return predicantsByName[pred].id;
              });
            }

            lexicon.blocks.forEach(function (block) {
              block.queries.forEach(function (query) {
                mapPredicantNamesToIds(query);

                if (query.responses) {
                  query.responses.forEach(mapPredicantNamesToIds);
                }
              });
            });
          });
        }

        function writeBlockQueries(block) {
          block.id = String(block.id);
          if (block.queries) {
            block.queries.forEach(function (query) {
              query.block = block.id;
            });

            return blockQueries.addAll(block.id, block.queries, {keepIds: true});
          }
        }

        return writePredicants().then(function () {
          var blocksWithoutQueries = lexicon.blocks.map(function (block) {
            return _.omit(block, 'queries');
          });
          return blocks.addAll(blocksWithoutQueries, {keepIds: true}).then(function () {
            return Promise.all(lexicon.blocks.map(function (block) {
              return writeBlockQueries(block);
            }));
          });
        });
      });
    },

    mapQueryPredicants: function(query, predicants) {
      var self = this;
      if (query.predicants) {
        query.predicants = query.predicants.map(function (pred) {
          return predicants[pred].name;
        });
      }

      if (query.responses) {
        query.responses.forEach(function(response) {
          if (response.predicants) {
            response.predicants = response.predicants.map(function (pred) {
              return predicants[pred].name;
            });
          }
        });
      }

      return query;
    },

    getLexicon: function() {
      var self = this;

      return this.predicants().then(function (predicants) {
        var predicantsById = _.indexBy(predicants, 'id');
        function getBlockQueries(block) {
          return blockQueries.list(block.id).then(function (queries) {
            block.queries = queries.map(function (query) {
              return self.mapQueryPredicants(query, predicantsById);
            });

            return block;
          });
        }

        return blocks.list().then(function (blocksList) {
          var sortedBlocks = _.sortBy(blocksList, function (b) { return Number(b.id); });

          return Promise.all(sortedBlocks.map(function (b) {
            return getBlockQueries(b);
          })).then(function (blocksWithQueries) {
            return {
              blocks: blocksWithQueries
            };
          });
        });
      });
    },

    queryById: function(id) {
      return queries.get(id);
    },

    updateQuery: function(id, query) {
      return queries.update(id, query).then(function () {
        return query;
      });
    },

    moveQueryAfter: function(blockId, queryId, afterQueryId) {
      return blockQueries.moveAfter(blockId, queryId, afterQueryId);
    },

    moveQueryBefore: function(blockId, queryId, beforeQueryId) {
      return blockQueries.moveBefore(blockId, queryId, beforeQueryId);
    },

    listBlocks: function() {
      return blocks.list().then(function(b) {
        return _.sortBy(b, function(x) {
          return Number(x.id);
        });
      });
    },

    blockById: function(id) {
      return blocks.get(id);
    },

    createBlock: function(block) {
      return blocks.add(block);
    },

    updateBlockById: function(id, block) {
      return blocks.update(id, block);
    },

    insertQueryBefore: function(blockId, queryId, query) {
      query.block = blockId;
      return blockQueries.insertBefore(blockId, queryId, query);
    },

    insertQueryAfter: function(blockId, queryId, query) {
      query.block = blockId;
      return blockQueries.insertAfter(blockId, queryId, query);
    },

    addQuery: function(blockId, query) {
      query.block = blockId;
      return blockQueries.add(blockId, query);
    },

    addQueryToUser: function(userId, query) {
      return userQueries.add(userId, query);
    },

    usagesForPredicant: function (predicantId) {
      return queries.list().then(function (queries) {
        var queriesRequiringPredicant = [];
        var queriesWithResponsesIssuingPredicant = [];

        queries.forEach(function (query) {
          if (query.predicants.indexOf(predicantId) >= 0) {
            queriesRequiringPredicant.push(query);
          }

          var responses = query.responses.filter(function (response) {
            return response.predicants.indexOf(predicantId) >= 0;
          });

          if (responses.length > 0) {
            queriesWithResponsesIssuingPredicant.push({
              query: query,
              responses: responses
            });
          }
        });

        return {
          queries: _.sortBy(queriesRequiringPredicant, 'name'),
          responses: _.sortBy(queriesWithResponsesIssuingPredicant, function (response) {
            return response.query.text;
          })
        };
      });
    },

    userQueries: function(userId, query) {
      return userQueries.list(userId);
    },

    deleteUserQuery: function(userId, queryId) {
      return userQueries.remove(userId, queryId);
    },

    deleteQuery: function(blockId, queryId) {
      return blockQueries.remove(blockId, queryId);
    },

    predicants: function(predicant) {
      return predicants.list();
    },

    predicantById: function (id) {
      return predicants.get(id);
    },

    removeAllPredicants: function() {
      return predicants.removeAll();
    },

    removePredicantById: function(id) {
      return predicants.remove(id);
    },

    addPredicant: function(predicant) {
      return predicants.add(predicant).then(function () {
        return predicant;
      });
    },

    addPredicants: function(p) {
      return predicants.addAll(p).then(function () {
        return p;
      });
    },

    updatePredicantById: function(id, predicant) {
      return predicants.update(id, predicant);
    },

    blockQueries: function(blockId) {
      return blockQueries.list(blockId);
    }
  };
};
