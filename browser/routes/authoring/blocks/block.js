var Promise = require("bluebird");
var React = require("react");
var ReactRouter = require("react-router");
var State = ReactRouter.State;
var Link = React.createFactory(ReactRouter.Link);
var r = React.createElement;
var Navigation = ReactRouter.Navigation;
var _ = require("underscore");
var queryComponent = require("./queries/query");
var moveItemInFromTo = require("./moveItemInFromTo");
var $ = require("../../../jquery");
var blockName = require("./blockName");
var queriesInHierarchyByLevel = require("./queriesInHierarchyByLevel");
var rjson = require("./rjson");
var reactBootstrap = require("react-bootstrap");
var DropdownButton = reactBootstrap.DropdownButton;
var MenuItem = reactBootstrap.MenuItem;

module.exports = React.createClass({
  mixins: [ State, Navigation ],
  getInitialState: function() {
    return {
      blocks: []
    };
  },

  componentDidMount: function() {
    var self = this;
    self.loadBlocks();
    self.loadBlock();
    self.loadQuery();
    self.loadClipboard();
    self.repositionQueriesList();
    self.resizeQueriesDiv();
    return $(window).on("scroll.repositionQueriesList", function() {
      return self.repositionQueriesList();
    });
  },

  componentWillUnmount: function() {
    return $(window).off("scroll.repositionQueriesList");
  },

  componentDidUpdate: function() {
    this.repositionQueriesList();
    this.resizeQueriesDiv();
  },

  repositionQueriesList: function() {
    if (this.state.blocks) {
      function pxNumber(x) {
        var m;
        m = /(.*)px$/.exec(x);
        if (m) {
          return Number(m[1]);
        } else {
          return 0;
        }
      }

      var element = this.getDOMNode();
      var buttons = $(element).find(".blocks-queries > .buttons");
      var marginBottom = buttons.css("margin-bottom");
      var top = Math.max(0, pxNumber(marginBottom) + buttons.offset().top + buttons.height() - Math.max(0, window.scrollY));
      var ol = $(element).find(".blocks-queries > ol");
      ol.css("top", top + "px");
    }
  },

  resizeQueriesDiv: function() {
    var element = this.getDOMNode();
    var queriesDiv = $(element).find(".left-panel");
    var queriesOl = $(element).find(".blocks-queries > ol");
    var width = queriesOl.outerWidth();
    queriesDiv.css("min-width", width + "px");
  },

  query: function() {
    var self = this;
    var block = this.block();
    if (block && block.queries) {
      return block.queries.filter(function (q) {
        return q.id == self.context.router.getCurrentParams().queryId;
      })[0];
    }
  },

  componentWillReceiveProps: function() {
    this.loadBlock();
    this.loadQuery();
  },

  loadBlocks: function() {
    var self = this;
    var blockSelf = self;

    function getBlocks() {
      return self.props.http.get("/api/blocks").then(function(blocks) {
        return blocks.map(function (b) {
          return {
            block: b,

            update: function () {
              var self = this;

              function getQueries() {
                return blockSelf.props.http.get("/api/blocks/" + b.id + "/queries").then(function(queries) {
                  return wait(200).then(function() {
                    self.queries = queries;
                    self.queriesHierarchy = queriesInHierarchyByLevel(queries);
                  });
                });
              }

              self.queriesPromise = getQueries();

              return self.queriesPromise.then(function() {
                blockSelf.setState({
                  blocks: blockSelf.state.blocks
                });

                if (blockSelf.blockId() === self.block.id) {
                  var query = blockSelf.query();
                  if (query) {
                    blockSelf.setState({
                      selectedQuery: query
                    });
                  }
                }
              });
            }
          };
        });
      }).then(function(blocks) {
        self.setState({
          blocks: blocks
        });
        return blocks;
      });
    }

    var blocksPromise = getBlocks();
    self.setState({
      blocksPromise: blocksPromise
    });

    return blocksPromise.then(function(latestBlocks) {
      latestBlocks.forEach(function(block) {
        return block.update();
      });

      if (!self.state.dirty && !self.isNewBlock()) {
        self.setState({
          selectedBlock: self.block()
        });
      }

      return latestBlocks;
    });
  },

  loadClipboard: function() {
    var self = this;
    return self.props.http.get("/api/user/queries").then(function(clipboard) {
      if (self.isMounted()) {
        return self.setState({
          clipboard: clipboard
        });
      }
    });
  },

  addToClipboard: function(query) {
    var self = this;
    return self.props.http.post("/api/user/queries", query).then(function() {
      return self.loadClipboard();
    });
  },

  removeFromClipboard: function(query) {
    var self = this;
    return self.props.http.delete(query.href).then(function() {
      return self.loadClipboard();
    });
  },

  loadQuery: function() {
    if (this.context.router.getCurrentParams().queryId) {
      if (this.queryId() !== this.context.router.getCurrentParams().queryId) {
        var query = this.query();
        if (query) {
          return this.setState({
            selectedQuery: query
          });
        }
      }
    } else if (this.context.router.getCurrentRoutes()[this.context.router.getCurrentRoutes().length - 1].name === "create_query") {
      if (!this.isNewQuery()) {
        return self.setState({
          selectedQuery: queryComponent.create({})
        });
      }
    } else {
      return this.setState({
        selectedQuery: void 0
      });
    }
  },

  loadBlock: function() {
    if (this.context.router.getCurrentParams().blockId) {
      if (this.blockId() !== this.context.router.getCurrentParams().blockId) {
        return this.setState({
          selectedBlock: this.block(),
          dirty: false
        });
      }
    } else if (this.context.router.getCurrentRoutes()[this.context.router.getCurrentRoutes().length - 1].name === "create_block") {
      if (!this.isNewBlock()) {
        return this.setState({
          selectedBlock: {
            block: {}
          }
        });
      }
    } else {
      return this.setState({
        selectedBlock: void 0
      });
    }
  },

  blockId: function() {
    return this.state.selectedBlock && this.state.selectedBlock.block && this.state.selectedBlock.block.id;
  },

  isNewBlock: function() {
    return this.state.selectedBlock && this.state.selectedBlock.block && !this.state.selectedBlock.block.id;
  },

  queryId: function() {
    return this.state.selectedQuery && this.state.selectedQuery.id;
  },

  isNewQuery: function() {
    return this.state.selectedQuery && !this.state.selectedQuery.id;
  },

  block: function() {
    var self = this;
    return self.state.blocks.filter(function (b) {
      return b.block.id === self.context.router.getCurrentParams().blockId;
    })[0];
  },

  addQuery: function() {
    var self = this;
    return self.context.router.transitionTo("create_query", {
      blockId: self.blockId()
    });
  },

  nameChanged: function(e) {
    var self = this;
    self.state.selectedBlock.block.name = e.target.value;
    self.update();
  },

  update: function(options) {
    var self = this;
    var dirty = options !== undefined && options.hasOwnProperty('dirty') && options.dirty !== undefined? options.dirty: true;
    return self.setState({
      selectedBlock: self.state.selectedBlock,
      dirty: dirty
    });
  },

  save: function() {
    var self = this;
    return self.props.http.post("/api/blocks/" + self.blockId(), self.state.selectedBlock.block).then(function() {
      return self.update({
        dirty: false
      });
    });
  },

  create: function() {
    var self = this;
    return self.props.http.post("/api/blocks", self.state.selectedBlock.block).then(function(savedBlock) {
      var id = savedBlock.id;
      self.loadBlocks();
      return self.context.router.replaceWith("block", {
        blockId: id
      });
    });
  },

  delete: function() {
    var self = this;
    self.state.selectedBlock.block.deleted = true;
    return self.props.http.post("/api/blocks/" + self.blockId(), self.state.selectedBlock.block).then(function() {
      self.loadBlocks();
      self.context.router.replaceWith("authoring");
    });
  },

  pasteQueryFromClipboard: function(query) {
    var self = this;
    if (query instanceof Function) {
      if (self.state.clipboardQuery) {
        query(self.state.clipboardQuery);
        self.setState({
          clipboardQuery: void 0
        });
      }
    } else {
      if (self.state.selectedQuery) {
        self.setState({
          clipboardQuery: query
        });
      }
    }
  },

  cancel: function() {
    return this.context.router.transitionTo("authoring");
  },

  createQuery: function(q) {
    var self = this;
    return self.props.http.post("/api/blocks/" + self.blockId() + "/queries", q).then(function(savedQuery) {
      var id = savedQuery.id;
      self.state.selectedBlock.update();
      self.context.router.replaceWith("query", {
        blockId: self.blockId(),
        queryId: id
      });
    });
  },

  updateQuery: function(q) {
    var self = this;
    return self.props.http.post("/api/blocks/" + self.blockId() + "/queries/" + q.id, q).then(function() {
      return self.state.selectedBlock.update();
    });
  },

  insertQueryBefore: function(q) {
    var self = this;
    q.before = q.id;
    q.id = void 0;
    return self.props.http.post("/api/blocks/" + self.blockId() + "/queries", q).then(function(query) {
      self.state.selectedBlock.update();
      self.context.router.replaceWith("query", {
        blockId: self.blockId(),
        queryId: query.id
      });
    });
  },

  insertQueryAfter: function(q) {
    var self = this;
    q.after = q.id;
    q.id = void 0;
    return self.props.http.post("/api/blocks/" + self.blockId() + "/queries", q).then(function(query) {
      self.state.selectedBlock.update();
      self.context.router.replaceWith("query", {
        blockId: self.blockId(),
        queryId: query.id
      });
    });
  },

  removeQuery: function(q) {
    var self = this;
    q.deleted = true;
    return self.props.http.post("/api/blocks/" + self.blockId() + "/queries/" + q.id, q).then(function() {
      self.setState({
        selectedQuery: void 0
      });
      self.state.selectedBlock.update();
      self.context.router.replaceWith("block", {
        blockId: self.blockId()
      });
    });
  },

  addBlock: function() {
    return this.context.router.transitionTo("create_block");
  },

  toggleClipboard: function(ev) {
    var self = this;
    ev.preventDefault();
    self.setState({
      showClipboard: !self.state.showClipboard
    });
  },

  textValue: function(value) {
    return value || "";
  },

  render: function() {
    function renderQueries(block, queries) {
      return r("ol", {}, queries.map(function (tree) {
        function selectQuery(ev) {
          if (tree.query) {
            self.context.router.replaceWith("query", {
              blockId: block.id,
              queryId: tree.query.id
            });
          }
          ev.stopPropagation();
        }

        function show(ev) {
          tree.hideQueries = false;
          self.setState({
            blocks: self.state.blocks
          });
          ev.stopPropagation();
        }

        function hide(ev) {
          tree.hideQueries = true;
          self.setState({
            blocks: self.state.blocks
          });
          ev.stopPropagation();
        }

        var selectedClass =
          (tree.query && self.queryId() === tree.query.id)
            ? "selected"
            : undefined;

        var toggle =
          tree.queries
            ? tree.hideQueries
              ? r("button", {className: "toggle", onClick: show},
                  r("span", {}, "+")
                )
              : r("button", {className: "toggle", onClick: hide},
                  r("span", {}, "-")
                )
            : undefined;

        return r("li", {},
          tree.query
            ? r("h4", {onClick: selectQuery, className: selectedClass}, toggle, tree.query.name)
            : undefined,
          (!tree.hideQueries && tree.queries)
            ? renderQueries(block, tree.queries)
            : undefined
        );
      }));
    }

    function addQuery() {
      self.context.router.transitionTo("create_query", {
        blockId: self.blockId()
      });
    }

    var self = this;
    return r("div", {className: "edit-block-query"},
      r("div", {className: "left-panel"},
        r("div", {className: "clipboard"},
          r("h2", {},
            r("a", {href: "#", onClick: self.toggleClipboard}, "Clipboard",
              self.state.clipboard
                ? " (" + self.state.clipboard.length + ")"
                : undefined
            )
          ),
          self.state.showClipboard
            ? r("ol", {},
                self.state.clipboard
                  ? self.state.clipboard.map(function (q) {
                      function pasteFromClipboard(ev) {
                        self.pasteQueryFromClipboard(q);
                        ev.preventDefault();
                      }

                      function removeFromClipboard(ev) {
                        self.removeFromClipboard(q);
                      }

                      return r("li", {onClick: pasteFromClipboard},
                        r("h4", {}, q.name),
                        r("button", {className: "button remove", onClick: removeFromClipboard}, "remove")
                      );
                    })
                  : undefined
              )
            : undefined
        ),
        self.state.blocks
          ? r("div", {className: "blocks-queries"},
              r("h2", {}, "Blocks"),
              r("div", {className: "buttons"},
                r("button", {onClick: self.addBlock}, "Add Block")
              ),
              r("ol", {}, self.state.blocks.map(function(blockViewModel) {
                var block = blockViewModel.block;

                function selectBlock(ev) {
                    self.context.router.replaceWith("block", {
                        blockId: block.id
                    });
                    return ev.stopPropagation();
                }

                function show(ev) {
                    blockViewModel.hideQueries = false;
                    self.setState({
                        blocks: self.state.blocks
                    });
                    return ev.stopPropagation();
                }

                function hide(ev) {
                    blockViewModel.hideQueries = true;
                    self.setState({
                        blocks: self.state.blocks
                    });
                    return ev.stopPropagation();
                }

                var selectedClass =
                  (self.blockId() === block.id)
                    ? "selected"
                    : undefined;

                return r("li", {},
                  r("h3", {onClick: selectBlock, className: selectedClass},
                    (blockViewModel.queries && blockViewModel.queries.length > 0)
                      ? blockViewModel.hideQueries
                        ? r("button", {className: "toggle", onClick: show}, "+")
                        : r("button", {className: "toggle", onClick: hide}, "-")
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
      ),
      (self.state.selectedBlock && self.state.selectedBlock.block)
        ? r("div", {className: "edit-block"},
            r("h2", {}, "Block"),
            r("div", {className: "buttons"},
              !self.blockId()
                ? r("button", {className: "create", onClick: self.create}, "Create")
                : self.state.dirty
                  ? r("button", {className: "save", onClick: self.save}, "Save")
                  : undefined,
              self.blockId()
                ? r("button", {className: "delete", onClick: self.delete}, "Delete")
                : undefined,
              (self.state.dirty || self.isNewBlock())
                ? r("button", {className: "cancel", onClick: self.cancel}, "Cancel")
                : r("button", {className: "cancel", onClick: self.cancel}, "Close")
            ),
            r("ul", {},
              r("li", {},
                r("label", {htmlFor: "block_name"}, "Name"),
                r("input", {
                  id: "block_name",
                  type: "text",
                  value: self.textValue(self.state.selectedBlock.block.name),
                  onChange: self.nameChanged
                })
              )
            ),
            (self.blockId() && self.state.selectedBlock.queries && self.state.selectedBlock.queries.length === 0)
              ? r("ul", {},
                  r("li", {},
                    r("button", {onClick: addQuery}, "Add Query")
                  )
                )
              : undefined,
            self.state.selectedQuery
              ? [
                  r("hr", {}),
                  React.createElement(queryComponent, {
                    http: self.props.http,
                    query: self.state.selectedQuery,
                    removeQuery: self.removeQuery,
                    updateQuery: self.updateQuery,
                    createQuery: self.createQuery,
                    insertQueryBefore: self.insertQueryBefore,
                    insertQueryAfter: self.insertQueryAfter,
                    pasteQueryFromClipboard: self.pasteQueryFromClipboard,
                    addToClipboard: self.addToClipboard
                  })
                ]
              : undefined
          )
        : r("div", {})
    );
  }
});

function wait(n) {
  return new Promise(function (fulfil) {
    setTimeout(fulfil, n);
  });
}
