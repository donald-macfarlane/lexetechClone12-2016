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
var dirtyBinding = require('./dirtyBinding');

_debug = require('debug');
var debug = _debug('block');

function BlockComponent() {
  this.blocks = [];

  var self = this;

  this.loadBlocks();
  this.predicants = predicants();

  this.loadQuery = throttle({throttle: 0}, this.loadQuery.bind(this));
  this.loadBlock = throttle({throttle: 0}, this.loadBlock.bind(this));

  this.loadClipboard();

  this.dirtyBinding = dirtyBinding(this);
}

BlockComponent.prototype.loadBlock = function (blockId, creatingBlock) {
  if (creatingBlock) {
    this.selectedBlock = this.createBlock({});
  } else {
    this.selectedBlock = this.block(blockId);
  }

  if (this.selectedBlock) {
    this.selectedBlock.startEditing();
  }
};

BlockComponent.prototype.loadQuery = function (queryId, creatingQuery) {
  if (creatingQuery) {
    this.selectedQuery = queryComponent.create();
  } else {
    this.selectedQuery = this.query(this.blockId, queryId);
  }

  if (this.selectedQuery) {
    this.queryComponent = queryComponent({
      query: clone(this.selectedQuery),
      originalQuery: this.selectedQuery,
      blockId: this.blockId,
      predicants: this.predicants,
      props: {
        removeQuery: this.removeQuery.bind(this),
        updateQuery: this.updateQuery.bind(this),
        createQuery: this.createQuery.bind(this),
        insertQueryBefore: this.insertQueryBefore.bind(this),
        insertQueryAfter: this.insertQueryAfter.bind(this),
        pasteQueryFromClipboard: this.pasteQueryFromClipboard.bind(this),
        addToClipboard: this.addToClipboard.bind(this)
      }
    });
  } else {
    delete this.queryComponent;
  }
};

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
    var ol = $(element).find(".blocks-queries > .menu");
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
  var queriesOl = $(element).find(".blocks-queries > .menu");
  var width = queriesOl.outerWidth();
  queriesDiv.css("min-width", width + "px");
};

BlockComponent.prototype.createBlock = function(b) {
  var blockSelf = this;

  return {
    block: b,

    startEditing: function () {
      this.editedBlock = clone(this.block);
    },

    cancelEdits: function () {
      this.editedBlock = clone(this.block);
    },

    commitEdits: function () {
      this.block = this.editedBlock;
    },

    updateQueries: function () {
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
        blockSelf.refresh(blockSelf.blocksComponent);
        blockSelf.refresh();
      });
    }
  };
}

BlockComponent.prototype.loadBlocks = function() {
  var self = this;
  self.blocksLoaded = false;

  function getBlocks() {
    return http.get("/api/blocks").then(function(blocks) {
      return blocks.map(function (b) {
        return self.createBlock(b);
      });
    }).then(function(blocks) {
      self.blocks = blocks;
      return blocks;
    });
  }

  this.blocksPromise = getBlocks();

  return this.blocksPromise.then(function(latestBlocks) {
    var allQueries = Promise.all(latestBlocks.map(function(block) {
      return block.updateQueries();
    })).then(function () {
      self.blocksLoaded = true;
      self.loadBlock.reset();
      self.loadQuery.reset();
      self.refresh();
      self.refresh(self.blocksComponent);
    });

    self.loadBlock.reset();
    self.loadQuery.reset();
    self.refresh();
    self.refresh(self.blocksComponent);
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

BlockComponent.prototype.isNewBlock = function() {
  return this.selectedBlock && this.selectedBlock.editedBlock && !this.selectedBlock.editedBlock.id;
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
  routes.authoringCreateQuery({blockId: this.blockId}).push();
};

BlockComponent.prototype.dirty = function(value) {
  this._dirty = true;
  return value;
};

BlockComponent.prototype.clean = function(value) {
  this._dirty = false;
  return value;
};

BlockComponent.prototype.save = function() {
  var self = this;
  return http.post("/api/blocks/" + self.blockId, self.selectedBlock.editedBlock).then(function() {
    self.selectedBlock.commitEdits();
    self.refresh(self.blocksComponent);
    self.clean();
  });
};

BlockComponent.prototype.create = function() {
  var self = this;
  return http.post("/api/blocks", self.selectedBlock.editedBlock).then(function(savedBlock) {
    self.clean();
    self.selectedBlock.commitEdits();
    var id = savedBlock.id;
    self.loadBlocks();
    routes.authoringBlock({blockId: id}).replace();
  });
};

BlockComponent.prototype.delete = function() {
  var self = this;
  self.selectedBlock.editedBlock.deleted = true;
  return http.post("/api/blocks/" + self.blockId, self.selectedBlock.editedBlock).then(function() {
    self.loadBlocks();
    routes.authoring().replace();
  });
};

BlockComponent.prototype.pasteQueryFromClipboard = function(query) {
  if (this.selectedQuery && this.queryComponent) {
    this.queryComponent.pasteQueryFromClipboard(query);
  }
};

BlockComponent.prototype.cancel = function() {
  this.selectedBlock.cancelEdits();
  routes.authoring().push();
};

BlockComponent.prototype.createQuery = function(q) {
  var self = this;
  return http.post("/api/blocks/" + self.blockId + "/queries", q).then(function(savedQuery) {
    self.selectedBlock.updateQueries();
    routes.authoringQuery({blockId: self.blockId, queryId: savedQuery.id}).replace();
  });
};

BlockComponent.prototype.updateQuery = function(q) {
  var self = this;
  return http.post("/api/blocks/" + self.blockId + "/queries/" + q.id, q).then(function() {
    return self.selectedBlock.updateQueries();
  });
};

BlockComponent.prototype.insertQueryBefore = function(q) {
  var self = this;
  q.before = q.id;
  q.id = void 0;
  return http.post("/api/blocks/" + self.blockId + "/queries", q).then(function(query) {
    self.selectedBlock.updateQueries();
    routes.authoringQuery({blockId: self.blockId, queryId: query.id}).replace();
  });
};

BlockComponent.prototype.insertQueryAfter = function(q) {
  var self = this;
  q.after = q.id;
  q.id = void 0;
  return http.post("/api/blocks/" + self.blockId + "/queries", q).then(function(query) {
    self.selectedBlock.updateQueries();
    routes.authoringQuery({blockId: self.blockId, queryId: query.id}).replace();
  });
};

BlockComponent.prototype.removeQuery = function(q) {
  var self = this;
  q.deleted = true;
  return http.post("/api/blocks/" + self.blockId + "/queries/" + q.id, q).then(function() {
    self.selectedBlock.updateQueries();
    routes.authoringBlock({blockId: self.blockId}).replace();
  });
};

BlockComponent.prototype.addBlock = function() {
  routes.authoringCreateBlock().push();
};

BlockComponent.prototype.renderPredicants = function () {
  var self = this;

  if (!this.predicantsComponent) {
    this.predicantsComponent = predicantsComponent({
      predicants: this.predicants
    });
  }

  return this.predicantsComponent.render();
};

BlockComponent.prototype.toggleClipboard = function(ev) {
  ev.preventDefault();
  this.showClipboard = !this.showClipboard;
};

BlockComponent.prototype.textValue = function(value) {
  return value || "";
};

BlockComponent.prototype.render = function() {
  var self = this;
  self.refresh = h.refresh;

  function load() {
    self.loadBlock(self.blockId, self.creatingBlock);
    self.loadQuery(self.queryId, self.creatingQuery);
  }

  function askToScrollBlockQueryMenu() {
    self.askToScrollBlockQueryMenu(self.blockId, self.queryId);
  }

  return h('.authoring-index.edit-lexicon',
    h("div.edit-block-query",
      routes.authoring(function () {
        load();
        return [
          self.renderBlocksQueries()
        ];
      }),
      routes.authoringCreateBlock(
        {
          onarrival: function () {
            delete self.blockId;
            self.creatingBlock = true;
            self.askToScrollBlockQueryMenu();
          },

          ondeparture: function () {
            self.creatingBlock = false;
          }
        },
        function (params) {
          load();
          return [
            self.renderBlocksQueries(),
            self.renderBlockEditor(params.blockId)
          ];
        }
      ),
      routes.authoringBlock(
        {
          onarrival: function () {
            self.askToScrollBlockQueryMenu();
          },

          blockId: [self, 'blockId']
        },
        function (params) {
          load();
          return [
            self.renderBlocksQueries(),
            self.renderBlockEditor(params.blockId)
          ];
        }
      ),
      routes.authoringPredicants.under(function () {
        load();
        return [
          self.renderBlocksQueries(),
          self.renderPredicants()
        ];
      }),
      routes.authoringCreateQuery(
        {
          onarrival: function () {
            delete self.queryId;
            self.creatingQuery = true;
            self.askToScrollBlockQueryMenu();
          },

          ondeparture: function () {
            self.creatingQuery = false;
          },

          blockId: [self, 'blockId']
        },
        function (params) {
          load();
          return [
            self.renderBlocksQueries(),
            self.renderBlockEditor(params.blockId, params.queryId)
          ];
        }
      ),
      routes.authoringQuery(
        {
          blockId: [self, 'blockId'],
          queryId: [self, 'queryId'],

          onarrival: function () {
            self.askToScrollBlockQueryMenu();
          },

          ondeparture: function () {
            delete self.blockId;
            delete self.queryId;
          }
        },
        function (params) {
          load();
          return [
            self.renderBlocksQueries(),
            self.renderBlockEditor(params.blockId, params.queryId)
          ];
        }
      )
    )
  );
};

BlockComponent.prototype.askToScrollBlockQueryMenu = function () {
  if (!this.ignoreScrollToBlockQuery) {
    this.scrollToBlockQuery = true;
  } else {
    this.ignoreScrollToBlockQuery = false;
  }
}

BlockComponent.prototype.renderBlocksQueries = function () {
  var self = this;

  function renderQueries(block, queries, options) {
    var top = options && options.top;

    return h(".menu", queries.map(function (tree) {
      function show(ev) {
        tree.hideQueries = false;
        ev.stopPropagation();
        self.refresh(self.blocksComponent);
      }

      function hide(ev) {
        tree.hideQueries = true;
        ev.stopPropagation();
        self.refresh(self.blocksComponent);
      }

      var toggle =
        tree.queries
          ? tree.hideQueries
            ? h("i.icon.chevron.right", {onclick: show})
            : h("i.icon.chevron.down", {onclick: hide})
          : h("i.icon", {onclick: hide});

      function selectQuery(ev) {
        self.ignoreScrollToBlockQuery = true;
        queryRoute.push();
        ev.stopPropagation();
        ev.preventDefault();
      }

      var queryRoute = tree.query? routes.authoringQuery({blockId: block.id, queryId: tree.query.id}): undefined;

      return h(".item", {class: {'no-query': !tree.query, active: tree.query && self.queryId === tree.query.id}},
        tree.query
          ? h(".header",
              toggle,
              h('a', {href: queryRoute.href, onclick: selectQuery}, tree.query.name)
            )
          : undefined,
        (!tree.hideQueries && tree.queries)
          ? renderQueries(block, tree.queries)
          : undefined
      );
    }));
  }

  return h.component(
    {
      key: 'edit-block-query',
      onadd: function (element) {
        function scroll() {
          console.log('scrolling');
          self.repositionQueriesList(element);
        }

        this.scroll = scroll;

        console.log('adding scroll listener');
        var wrapper = document.getElementById('wrapper');
        if (wrapper) {
          wrapper.addEventListener('scroll', scroll);
        }
        self.repositionQueriesList(element);
        self.resizeQueriesDiv(element);
      },

      onupdate: function (element) {
        self.resizeQueriesDiv(element);
        self.repositionQueriesList(element);

        function relativePosition(element, ancestor) {
          var top = 0;
          var left = 0;

          while(element.offsetParent && ancestor !== element) {
            top += element.offsetTop;
            left += element.offsetLeft;
            element = element.offsetParent;
          }

          return {
            top: top,
            left: left
          }
        }

        if (self.scrollToBlockQuery && self.blocksLoaded) {
          self.scrollToBlockQuery = false;
          var items = element.querySelectorAll('.item.active');
          var item = items[items.length - 1];
          var menu = element.querySelector('.ui.menu.results');
          if (item && menu) {
            menu.scrollTop = relativePosition(item, menu).top - 60;
          }
        }
      },

      onremove: function () {
        window.removeEventListener('scroll', this.scroll);
      }
    },
    function () {
      return h("div.left-panel",
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
        self.blocksComponent = self.blocks
          ? h.component({cacheKey: self.blockId + ':' + self.queryId},
              function () {
                return h(".blocks-queries",
                  h("h2", "Blocks"),
                  h("div.buttons",
                    h("button", {onclick: self.addBlock.bind(self)}, "Add Block"),
                    h("button", {onclick: routes.authoringPredicants().push}, "Predicants")
                  ),
                  h(".ui.vertical.menu.results", self.blocks.map(function(blockViewModel) {
                    var block = blockViewModel.block;

                    function selectBlock(ev) {
                      self.ignoreScrollToBlockQuery = true;
                      blockRoute.push();
                      ev.preventDefault();
                      ev.stopPropagation();
                    }

                    function show(ev) {
                      blockViewModel.hideQueries = false;
                      ev.stopPropagation();
                      self.refresh(self.blocksComponent);
                    }

                    function hide(ev) {
                      blockViewModel.hideQueries = true;
                      ev.stopPropagation();
                      self.refresh(self.blocksComponent);
                    }

                    var toggle =
                      (blockViewModel.queries && blockViewModel.queries.length > 0)
                        ? blockViewModel.hideQueries
                          ? h("i.icon.chevron.right", {onclick: show})
                          : h("i.icon.chevron.down", {onclick: hide})
                        : h("i.icon", {onclick: hide});

                    var blockRoute = routes.authoringBlock({blockId: block.id});

                    return h('.item', {class: {active: self.blockId === block.id}},
                      h(".header",
                        toggle,
                        h('a', {href: blockRoute.href, onclick: selectBlock}, blockName(block))
                      ),
                      (!blockViewModel.hideQueries && blockViewModel.queriesHierarchy)
                        ? renderQueries(block, blockViewModel.queriesHierarchy)
                        : undefined
                    );
                  }))
                );
              }
            )
          : undefined
      );
    }
  );
};

BlockComponent.prototype.renderBlockEditor = function (blockId, queryId) {
  var self = this;

  function addQuery() {
    routes.authoringCreateQuery({blockId: self.blockId}).push();
  }

  if (self.selectedBlock) {
    return h("div.edit-block",
      h("h2", "Block"),
      h("div.buttons",
        !self.selectedBlock.editedBlock.id
          ? h("button.create", {onclick: self.create.bind(self)}, "Create")
          : self._dirty
            ? h("button.save", {onclick: self.save.bind(self)}, "Save")
            : undefined,
        self.selectedBlock.editedBlock.id
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
            binding: self.dirtyBinding(self.selectedBlock.editedBlock, 'name')
          })
        )
      ),
      (self.blockId && self.selectedBlock.queries && self.selectedBlock.queries.length === 0)
        ? h("ul",
            h("li",
              h("button", {onclick: addQuery}, "Add Query")
            )
          )
        : undefined,
      this.queryComponent
        ? this.queryComponent.render()
        : undefined
    );
  }
};

module.exports = function () {
  return new BlockComponent();
};

function wait(n) {
  return new Promise(function (fulfil) {
    setTimeout(fulfil, n);
  });
}
