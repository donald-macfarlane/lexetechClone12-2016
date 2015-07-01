var Promise = require("bluebird");
var _ = require("underscore");
var queryComponent = require("./queries/queryComponent");
var $ = require("../../../jquery");
var blockName = require("./blockName");
var queriesInHierarchyByLevel = require("./queriesInHierarchyByLevel");
var h = require('plastiq').html;
var throttle = require('plastiq-throttle');
var http = require('../../../http');
var routes = require('../../../routes');
var clone = require('./queries/clone');
var predicantsComponent = require('./predicantsComponent');
var predicants = require('./predicants');

_debug = require('debug');
var debug = _debug('block');

function BlockComponent() {
  this.blocks = [];

  var self = this;

  this.loadBlocks();
  this.loadBlock = throttle(function (blockId, blocksLoaded) {
    self.selectedBlock = self.block(blockId);
  });

  this.predicants = predicants();

  this.loadQuery = throttle(function (blockId, queryId, blocksLoaded) {
    self.selectedQuery = self.query(blockId, queryId);

    if (self.selectedQuery) {
      self.queryComponent = queryComponent({
        query: clone(self.selectedQuery),
        originalQuery: self.selectedQuery,
        blockId: self.selectedBlock.id,
        predicants: self.predicants,
        props: {
          removeQuery: self.removeQuery,
          updateQuery: self.updateQuery,
          createQuery: self.createQuery,
          insertQueryBefore: self.insertQueryBefore,
          insertQueryAfter: self.insertQueryAfter,
          pasteQueryFromClipboard: self.pasteQueryFromClipboard,
          addToClipboard: self.addToClipboard
        }
      });
    } else {
      delete self.queryComponent;
    }
  });

  this.loadClipboard();

  this.dirtyBinding = function (model, property) {
    return {
      get: function () {
        return model[property];
      },

      set: function (value) {
        console.log('dirty binding');
        self._dirty = true;
        model[property] = value;
      }
    };
  };
}

BlockComponent.prototype.repositionQueriesList = function (element) {
  if (this.blocks) {
    function pxNumber(x) {
      var m;
      m = /(.*)px$/.exec(x);
      if (m) {
        return Number(m[1]);
      } else {
        return 0;
      }
    }

    var buttons = $(element).find(".blocks-queries > .buttons");
    var marginBottom = buttons.css("margin-bottom");
    var top = Math.max(0, pxNumber(marginBottom) + buttons.offset().top + buttons.height() - Math.max(0, window.scrollY));
    var ol = $(element).find(".blocks-queries > ol");
    ol.css("top", top + "px");
  }
};

BlockComponent.prototype.query = function(blockId, queryId) {
  var self = this;
  var block = this.block(blockId);
  if (block && block.queries) {
    return block.queries.filter(function (q) {
      return q.id == queryId;
    })[0];
  }
};

BlockComponent.prototype.resizeQueriesDiv = function(element) {
  var queriesDiv = $(element);
  var queriesOl = $(element).find(".blocks-queries > ol");
  var width = queriesOl.outerWidth();
  queriesDiv.css("min-width", width + "px");
};

BlockComponent.prototype.loadBlocks = function() {
  var self = this;
  var blockSelf = self;

  function getBlocks() {
    return http.get("/api/blocks").then(function(blocks) {
      return blocks.map(function (b) {
        return {
          block: b,

          update: function () {
            var self = this;

            function getQueries() {
              return http.get("/api/blocks/" + b.id + "/queries").then(function(queries) {
                return wait(200).then(function() {
                  self.queries = queries;
                  self.queriesHierarchy = queriesInHierarchyByLevel(queries);
                });
              });
            }

            self.queriesPromise = getQueries();

            return self.queriesPromise.then(function() {
              blockSelf.refresh();
            });
          }
        };
      });
    }).then(function(blocks) {
      self.blocks = blocks;
      return blocks;
    });
  }

  this.blocksPromise = getBlocks();

  return this.blocksPromise.then(function(latestBlocks) {
    var allQueries = Promise.all(latestBlocks.map(function(block) {
      return block.update();
    })).then(function () {
      self.blocksLoaded = true;
      self.refresh();
    });

    self.refresh();
    return latestBlocks;
  });
};

BlockComponent.prototype.loadClipboard = function() {
  var self = this;
  return http.get("/api/user/queries").then(function(clipboard) {
    self.clipboard = clipboard;
  });
};

BlockComponent.prototype.addToClipboard = function(query) {
  var self = this;
  return http.post("/api/user/queries", query).then(function() {
    return self.loadClipboard();
  });
};

BlockComponent.prototype.removeFromClipboard = function(query) {
  var self = this;
  return http.delete(query.href).then(function() {
    return self.loadClipboard();
  });
};

BlockComponent.prototype.blockId = function() {
  return this.selectedBlock && this.selectedBlock.block && this.selectedBlock.block.id;
};

BlockComponent.prototype.isNewBlock = function() {
  return this.selectedBlock && this.selectedBlock.block && !this.selectedBlock.block.id;
};

BlockComponent.prototype.queryId = function() {
  return this.selectedQuery && this.selectedQuery.id;
};

BlockComponent.prototype.isNewQuery = function() {
  return this.selectedQuery && !this.selectedQuery.id;
};

BlockComponent.prototype.block = function(blockId) {
  var self = this;
  return self.blocks.filter(function (b) {
    return b.block.id === blockId;
  })[0];
};

BlockComponent.prototype.addQuery = function() {
  routes.authoringCreateQuery({blockId: this.blockId()}).push();
};

BlockComponent.prototype.dirty = function(value) {
  console.log('dirty');
  this._dirty = true;
  return value;
};

BlockComponent.prototype.clean = function(value) {
  this._dirty = false;
  return value;
};

BlockComponent.prototype.save = function() {
  var self = this;
  return http.post("/api/blocks/" + self.blockId(), self.selectedBlock.block).then(function() {
    return self.clean();
  });
};

BlockComponent.prototype.create = function() {
  var self = this;
  return http.post("/api/blocks", self.selectedBlock.block).then(function(savedBlock) {
    var id = savedBlock.id;
    self.loadBlocks();
    routes.authoringBlock({blockId: id}).replace();
  });
};

BlockComponent.prototype.delete = function() {
  var self = this;
  self.selectedBlock.block.deleted = true;
  return http.post("/api/blocks/" + self.blockId(), self.selectedBlock.block).then(function() {
    self.loadBlocks();
    routes.authoring().replace();
  });
};

BlockComponent.prototype.pasteQueryFromClipboard = function(query) {
  if (query instanceof Function) {
    if (this.clipboardQuery) {
      query(this.clipboardQuery);
      delete this.clipboardQuery;
    }
  } else {
    if (this.selectedQuery) {
      this.clipboardQuery = query;
    }
  }
};

BlockComponent.prototype.cancel = function() {
  routes.authoring().push();
};

BlockComponent.prototype.createQuery = function(q) {
  var self = this;
  return http.post("/api/blocks/" + self.blockId() + "/queries", q).then(function(savedQuery) {
    self.selectedBlock.update();
    routes.authoringQuery({blockId: self.blockId(), queryId: savedQuery.id}).replace();
  });
};

BlockComponent.prototype.updateQuery = function(q) {
  var self = this;
  return http.post("/api/blocks/" + self.blockId() + "/queries/" + q.id, q).then(function() {
    return self.selectedBlock.update();
  });
};

BlockComponent.prototype.insertQueryBefore = function(q) {
  var self = this;
  q.before = q.id;
  q.id = void 0;
  return http.post("/api/blocks/" + self.blockId() + "/queries", q).then(function(query) {
    self.selectedBlock.update();
    routes.authoringQuery({blockId: self.blockId(), queryId: query.id}).replace();
  });
};

BlockComponent.prototype.insertQueryAfter = function(q) {
  var self = this;
  q.after = q.id;
  q.id = void 0;
  return http.post("/api/blocks/" + self.blockId() + "/queries", q).then(function(query) {
    self.selectedBlock.update();
    routes.authoringQuery({blockId: self.blockId(), queryId: query.id}).replace();
  });
};

BlockComponent.prototype.removeQuery = function(q) {
  var self = this;
  q.deleted = true;
  return http.post("/api/blocks/" + self.blockId() + "/queries/" + q.id, q).then(function() {
    self.selectedBlock.update();
    routes.authoringBlock({blockId: self.blockId()}).replace();
  });
};

BlockComponent.prototype.addBlock = function() {
  routes.authoringCreateBlock().push();
};

BlockComponent.prototype.showPredicants = function () {
  var self = this;

  this.predicantsComponent = predicantsComponent({
    onclose: function () {
      delete self.predicantsComponent;
    },
    predicants: this.predicants
  });
};

BlockComponent.prototype.toggleClipboard = function(ev) {
  ev.preventDefault();
  this.showClipboard = !this.showClipboard;
};

BlockComponent.prototype.textValue = function(value) {
  return value || "";
};

BlockComponent.prototype.render = function(blockId, queryId) {
  var self = this;
  self.refresh = h.refresh;

  self.loadBlock(blockId, self.blocksLoaded);
  self.loadQuery(blockId, queryId, self.blocksLoaded);

  function renderQueries(block, queries) {
    return h("ol", queries.map(function (tree) {
      function selectQuery(ev) {
        if (tree.query) {
          routes.authoringQuery({ blockId: block.id, queryId: tree.query.id}).replace();
        }
        ev.stopPropagation();
      }

      function show(ev) {
        tree.hideQueries = false;
        ev.stopPropagation();
      }

      function hide(ev) {
        tree.hideQueries = true;
        ev.stopPropagation();
      }

      var toggle =
        tree.queries
          ? tree.hideQueries
            ? h("button.toggle", {onclick: show},
                h("span", "+")
              )
            : h("button.toggle", {onclick: hide},
                h("span", "-")
              )
          : undefined;

      return h("li",
        tree.query
          ? h("h4",
              {onclick: selectQuery, class: {selected: tree.query && self.queryId() === tree.query.id}},
              toggle,
              tree.query.name
            )
          : undefined,
        (!tree.hideQueries && tree.queries)
          ? renderQueries(block, tree.queries)
          : undefined
      );
    }));
  }

  function addQuery() {
    routes.authoringCreateQuery({blockId: self.blockId()}).push();
  }

  return h('.authoring-index.edit-lexicon',
    h("div.edit-block-query",
      h.component(
        {
          onadd: function (element) {
            function scroll() {
              self.repositionQueriesList(element);
            }

            this.scroll = scroll;

            window.addEventListener('scroll', scroll);
            self.repositionQueriesList(element);
            self.resizeQueriesDiv(element);
          },

          onupdate: function (element) {
            self.resizeQueriesDiv(element);
          },

          onremove: function () {
            window.removeEventListener('scroll', this.scroll);
          }
        },
        h("div.left-panel",
          h("div.clipboard",
            h("h2",
              h("a", {href: "#", onclick: self.toggleClipboard.bind(self)}, "Clipboard",
                self.clipboard
                  ? " (" + self.clipboard.length + ")"
                  : undefined
              )
            ),
            self.showClipboard
              ? h("ol",
                  self.clipboard
                    ? self.clipboard.map(function (q) {
                        function pasteFromClipboard(ev) {
                          self.pasteQueryFromClipboard(q);
                          ev.preventDefault();
                        }

                        function removeFromClipboard(ev) {
                          self.removeFromClipboard(q);
                        }

                        return h("li", {onclick: pasteFromClipboard},
                          h("h4", q.name),
                          h("button.button.remove", {onclick: removeFromClipboard}, "remove")
                        );
                      })
                    : undefined
                )
              : undefined
          ),
          self.blocks
            ? h("div.blocks-queries",
                h("h2", "Blocks"),
                h("div.buttons",
                  h("button", {onclick: self.addBlock.bind(self)}, "Add Block"),
                  h("button", {onclick: self.showPredicants.bind(self)}, "Predicants")
                ),
                h("ol", self.blocks.map(function(blockViewModel) {
                  var block = blockViewModel.block;

                  function selectBlock(ev) {
                    routes.authoringBlock({blockId: block.id}).replace();
                    return ev.stopPropagation();
                  }

                  function show(ev) {
                    blockViewModel.hideQueries = false;
                    ev.stopPropagation();
                  }

                  function hide(ev) {
                    blockViewModel.hideQueries = true;
                    ev.stopPropagation();
                  }

                  return h("li",
                    h("h3", {onclick: selectBlock, class: {selected: self.blockId() === block.id}},
                      (blockViewModel.queries && blockViewModel.queries.length > 0)
                        ? blockViewModel.hideQueries
                          ? h("button.toggle", {onclick: show}, "+")
                          : h("button.toggle", {onclick: hide}, "-")
                        : undefined,
                      blockName(block)
                    ),
                    (!blockViewModel.hideQueries && blockViewModel.queriesHierarchy)
                      ? renderQueries(block, blockViewModel.queriesHierarchy)
                      : undefined
                  );
                }))
              )
            : undefined
        )
      ),
      (self.selectedBlock && self.selectedBlock.block)
        ? h("div.edit-block",
            h("h2", {}, "Block"),
            h("div.buttons",
              !self.blockId()
                ? h("button.create", {onclick: self.create.bind(self)}, "Create")
                : self._dirty
                  ? h("button.save", {onclick: self.save.bind(self)}, "Save")
                  : undefined,
              self.blockId()
                ? h("button.delete", {onclick: self.delete.bind(self)}, "Delete")
                : undefined,
              (self._dirty || self.isNewBlock())
                ? h("button.cancel", {onclick: self.cancel.bind(self)}, "Cancel")
                : h("button.cancel", {onclick: self.cancel.bind(self)}, "Close")
            ),
            h("ul",
              h("li",
                h("label", {for: "block_name"}, "Name"),
                h("input", {
                  id: "block_name",
                  type: "text",
                  binding: self.dirtyBinding(self.selectedBlock.block, 'name')
                })
              )
            ),
            (self.blockId() && self.selectedBlock.queries && self.selectedBlock.queries.length === 0)
              ? h("ul",
                  h("li",
                    h("button", {onclick: addQuery}, "Add Query")
                  )
                )
              : undefined,
            self.selectedQuery
              ? [
                  h("hr"),
                  self.queryComponent.render()
                ]
              : undefined
          )
        : h("div"),
      self.predicantsComponent
        ? self.predicantsComponent.render()
        : undefined
    )
  );
};

module.exports = function () {
  return new BlockComponent();
};

function wait(n) {
  return new Promise(function (fulfil) {
    setTimeout(fulfil, n);
  });
}
