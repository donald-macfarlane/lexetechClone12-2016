var Promise = require("bluebird");
var self = this;
var React = require("react");
var r = React.createElement;
var ReactRouter = require("react-router");
var Navigation = ReactRouter.Navigation;
var _ = require("underscore");
var sortableReact = require("../sortable");
var moveItemInFromTo = require("../moveItemInFromTo");
var blockName = require("../blockName");
var responseHtmlEditor = require("../../../../responseHtmlEditor");
var reactBootstrap = require("react-bootstrap");
var DropdownButton = reactBootstrap.DropdownButton;
var MenuItem = reactBootstrap.MenuItem;
var plastiq = require('plastiq');
var h = plastiq.html;
var semanticUi = require('plastiq-semantic-ui');

function sortable(options) {
  return options.render();
}

function menuItem() {
  var args = Array.prototype.slice.call(arguments);
  args.unshift('.item');
  return h.apply(undefined, args);
}

function dropdownButton() {
  var args = Array.prototype.slice.call(arguments);
  args.unshift('.drop-down-button');
  return h.apply(undefined, args);
}

function clone(obj) {
  return JSON.parse(JSON.stringify(obj));
}

module.exports = React.createClass({
  mixins: [ ReactRouter.State, Navigation ],

  getInitialState: function() {
    return {
      query: module.exports.create(),
      predicants: [],
      lastResponseId: 0
    };
  },

  componentDidMount: function() {
    var self = this;

    function loadPredicants() {
      return Promise.all([
        self.props.http.get("/api/predicants"),
        self.props.http.get("/api/users", {suppressErrors: true}).then(undefined, function (error) {
          // user doesn't have admin access to see users
          // don't show users
          if (error.status != 403) {
            throw error;
          }
        })
      ]).then(function(results) {
        var predicants = results[0];
        var users = results[1];

        if (users) {
          users.forEach(function (user) {
            var id = 'user:' + user.id;
            var name = user.firstName + ' ' + user.familyName;
            predicants[id] = {
              id: id,
              name: name
            };
          });
        }

        if (self.isMounted()) {
          return self.setState({
            predicants: predicants
          });
        }
      });
    }

    function loadBlocks() {
      return self.props.http.get("/api/blocks").then(function(blockList) {
        var blocks = _.indexBy(blockList, "id");

        if (self.isMounted()) {
          return self.setState({
            blocks: blocks
          });
        }
      });
    }

    this.setState({
      query: clone(this.props.query)
    });

    loadPredicants();
    loadBlocks();

    plastiq.append(this.getDOMNode(), this.renderPlastiq.bind(this), this.state);
  },

  componentWillReceiveProps: function(newprops) {
    var self = this;
    var clipboardPaste = false;

    newprops.pasteQueryFromClipboard(function(clipboardQuery) {
      clipboardPaste = true;
      _.extend(self.state.query, _.omit(clipboardQuery, "level", "id"));
      return self.setState({
        query: self.state.query,
        dirty: true
      });
    });

    if (!self.state.dirty && !clipboardPaste) {
      self.setState({
        query: clone(newprops.query),
        selectedResponse: undefined
      });
    }
  },

  bind: function(model, field, transform) {
    var self = this;

    return function(ev) {
      if (transform) {
        model[field] = transform(ev.target.value);
      } else {
        model[field] = ev.target.value;
      }

      self.update();
    };
  },

  bindHtml: function(model, field, transform) {
    var self = this;

    return function(html) {
      if (transform) {
        model[field] = transform(html);
      } else {
        model[field] = html;
      }

      self.update();
    };
  },

  textValue: function(value) {
    return value || "";
  },

  highestResponseId: function() {
    var self = this;

    if (self.state.query.responses.length) {
      return _.max(self.state.query.responses.map(function (r) { return Number(r.id); }));
    } else {
      return 0;
    }
  },

  addResponse: function() {
    var self = this;

    var id = self.highestResponseId() + 1;
    var response = {
      text: "",
      predicants: [],
      styles: {
        style1: "",
        style2: ""
      },
      actions: [],
      id: id
    };

    self.state.query.responses.push(response);
    self.update();

    self.setState({
      selectedResponse: response
    });
  },

  update: function(options) {
    var self = this;
    var dirty = options && options.hasOwnProperty('dirty') && options.dirty !== undefined? options.dirty: true;

    self.setState({
      dirty: dirty
    });
  },

  renderActions: function(actions) {
    var self = this;
    var hasSetOrAddBlocks;

    function addAction(action) {
      actions.push(action);
      self.update();
    }

    function removeAction(action) {
      removeFrom(action, actions);
      self.update();
    }

    function addActionClick(createAction) {
      return function(ev) {
        var action;
        action = createAction();
        addAction(action);
        ev.preventDefault();
      };
    }

    var hasRepeat = actions.filter(function (a) { return a.name == 'repeatLexeme'; }).length > 0;
    var hasSetOrAddBlocks = actions.filter(function (a) {
      return a.name == 'setBlocks' || a.name == 'addBlocks';
    }).length > 0;

    return h("div",
      h("ol",
        actions.map(function (action) {
          function remove() {
            removeAction(action);
          }
          return self.renderAction(action, remove);
        })
      ),
      semanticUi.dropdown(
        h('.ui.floating.dropdown.icon.button',
          h('i.dropdown', 'Add Action'),
          h('.menu',
            !hasRepeat && !hasSetOrAddBlocks
              ? menuItem({
                  onclick: addActionClick(function() {
                    return {
                      name: "setBlocks",
                      arguments: []
                    };
                  })
                }, "Set Blocks")
              : undefined,

            !hasRepeat && !hasSetOrAddBlocks
              ? menuItem({
                  onclick: addActionClick(function() {
                    return {
                      name: "addBlocks",
                      arguments: []
                    };
                  })
                }, "Add Blocks")
              : undefined,

            menuItem(
              {
                onclick: addActionClick(function() {
                  return {
                    name: "repeatLexeme",
                    arguments: []
                  };
                })
              },
              "Repeat"
            ),
            menuItem(
              {
                onclick: addActionClick(function() {
                  return {
                    name: "setVariable",
                    arguments: [ "", "" ]
                  };
                })
              },
              "Set Variable"
            ),
            menuItem(
              {
                onclick: addActionClick(function() {
                  return {
                    name: "suppressPunctuation",
                    arguments: []
                  };
                })
              },
              "Suppress Punctuation"
            ),
            menuItem(
              {
                onclick: addActionClick(function() {
                  return {
                    name: "loadFromFile",
                    arguments: []
                  };
                })
              },
              "Load from File"
            ),
            menuItem(
              {
                onclick: addActionClick(function() {
                  return {
                    name: "loopBack",
                    arguments: []
                  };
                })
              },
              "Loop Back"
            )
          )
        )
      )
    );
  },

  renderAction: function(action, removeAction) {
      var self = this;

      function removeButton() {
        return h("div.buttons",
          h("button.remove-action", {
            onclick: removeAction
          }, "Remove")
        );
      }

      function blocks(name, $class) {
        function setArguments(blockIds) {
          action.arguments.splice(0, action.arguments.length);
          action.arguments.push.apply(action.arguments, blockIds.filter(function (id) { return self.state.blocks[id]; }));
          self.update();
        }

        function addBlock(block) {
          action.arguments.push(block.id);
          self.update();
        }

        function removeBlock(block) {
          removeFrom(block.id, action.arguments);
          self.update();
        }

        function renderArguments() {
          var args = action.arguments.map(function (id) {
            var b = self.state.blocks[id];

            function remove() {
              removeBlock(b);
            }

            return h("li",
              h("span", blockName(b)),
              h.rawHtml("button.remove-block.remove",
                { onclick: remove },
                "&cross;"
              )
            );
          });

          return h("ol", args);
        }

        function itemMoved(from, to) {
          moveItemInFromTo(action.arguments, from, to);
          self.update();
        }

        var filterBlocksConversion = {
          text: function (numbers) {
            return numbers;
          },

          value: function (numbers) {
            return numbers.filter(function (n) { return self.state.blocks[n]; });
          }
        };

        var numberArray = {
          text: function (numbers) {
            return numbers.map(Number);
          },

          value: function (numbers) {
            return numbers.map(String);
          }
        };

        return h('li', {class: $class},
          h('h4', name),
          self.state.blocks
            ? [
                h('input', {type: 'text', binding: [action, 'arguments', numberArray, filterBlocksConversion, rangeConversion]}),
                sortable({
                  itemMoved: itemMoved,
                  render: renderArguments
                }),
                itemSelect({
                  onAdd: addBlock,
                  onRemove: removeBlock,
                  selectedItems: action.arguments,
                  items: self.state.blocks,
                  renderItemText: blockName,
                  placeholder: "add block"
                })
              ]
            : undefined,
          removeButton()
        );
      }

      var renderAction = {
        setBlocks: function(action) {
          return blocks("Set Blocks", "action-set-blocks");
        },

        addBlocks: function(action) {
          return blocks("Add Blocks", "action-add-blocks");
        },

        setVariable: function(action) {
          return h("li",
            h("h4", "Set Variable"),
            h("ul",
              h("li",
                h("label", "Name"),
                h("input",
                  {
                    type: "text",
                    binding: [action, 0]
                  }
                )
              ),
              h("li",
                h("label","Value"),
                h("input",
                  {
                    type: "text",
                    binding: [action, 1]
                  }
                )
              )
            ),
            removeButton()
          );
        },

        repeatLexeme: function(action) {
          return h("li",
            h("h4", "Repeat Lexeme"),
            removeButton()
          );
        },

        suppressPunctuation: function(action) {
          return h("li",
            h("h4", "Suppress Punctuation"),
            removeButton()
          );
        },

        loadFromFile: function(action) {
          return h("li",
            h("h4", "Load from File"),
            removeButton()
          );
        }
      }[action.name];

      if (renderAction) {
        return renderAction.call(self, action);
      }
  },

  renderPredicants: function(predicants) {
    var self = this;

    function addPredicant(predicant) {
      predicants.push(predicant.id);
      self.update();
    }

    function removePredicant(predicant) {
      removeFrom(predicant.id, predicants);
      self.update();
    }

    if (Object.keys(self.state.predicants).length > 0) {
      function renderPredicant(id) {
        var p = self.state.predicants[id];

        function remove() {
          return removePredicant(p);
        }

        return h("li",
          h("span", p.name),
          h.rawHtml("button.remove-predicant.remove",
            {
              onclick: remove
            },
            "&cross;"
          )
        );
      }

      return h("div.predicants",
        h("ol", predicants.map(renderPredicant)),
        itemSelect({
          onAdd: addPredicant,
          onRemove: removePredicant,
          selectedItems: predicants,
          items: self.state.predicants,
          placeholder: "add predicant"
        })
      );
    }
  },

  save: function() {
    var self = this;

    return self.props.updateQuery(self.state.query).then(function() {
      return self.update({dirty: false});
    });
  },

  create: function() {
    var self = this;

    return self.props.createQuery(self.state.query).then(function() {
      return self.update({dirty: false});
    });
  },

  "delete": function() {
    return this.props.removeQuery(this.state.query);
  },

  insertBefore: function() {
    var self = this;
    return self.props.insertQueryBefore(self.state.query).then(function() {
      return self.update({dirty: false});
    });
  },

  insertAfter: function() {
    var self = this;
    return self.props.insertQueryAfter(self.state.query).then(function() {
      return self.update({dirty: false});
    });
  },

  numberInput: function(model, field) {
    return h("input",
      {
        type: "number",
        binding: [model, field, Number],
        onfocus: function(ev) {
          return $(ev.target).on("mousewheel.disableScroll", function(ev) {
            ev.preventDefault();
          });
        },
        onblur: function(ev) {
          return $(ev.target).off("mousewheel.disableScroll");
        }
      }
    );
  },

  cancel: function() {
    var self = this;
    var copy = clone(this.props.query);
    var selectedResponse =
      this.state.selectedResponse
        ? copy.responses.filter(function (response) {
          return response.id === self.state.selectedResponse.id;
        })[0]
        : undefined;

    return this.setState({
      query: copy,
      selectedResponse: selectedResponse,
      dirty: false
    });
  },

  close: function() {
    return this.context.router.transitionTo("block", {
      blockId: this.getParams().blockId
    });
  },

  addToClipboard: function() {
    return this.props.addToClipboard(this.state.query);
  },

  renderResponse: function (response) {
    var self = this;

    function remove() {
      self.state.query.responses = _.without(self.state.query.responses, response);
      return self.update();
    }

    function select() {
      return self.setState({
        selectedResponse: response
      });
    }

    function deselect() {
      return self.setState({
        selectedResponse: undefined
      });
    }

    var editing = self.state.selectedResponse === response;

    function renderStyle(style) {
      if (editing) {
        return responseHtmlEditor({ class: 'editor', binding: [response.styles, style]});
      } else {
        return h.rawHtml('div.editor', response.styles[style]);
      }
    }

    return h("li", { key: response.id },
      [
        editing
          ? h("div.buttons.top",
              h("button.close", {onclick: deselect}, "Close")
            )
          : undefined,
        h("ul",
          h("li.selector",
            h("label", "Selector"),
            h("textarea", {binding: [response, 'text'], onfocus: select})
          ),
          h("li.set-level",
            h("label", "Set Level"),
            self.numberInput(response, "setLevel")
          ),
          h("li.style1",
            h("label", "Style 1"),
            renderStyle('style1')
          ),
          h("li.style2",
            h("label", "Style 2"),
            renderStyle('style2')
          ),
          h("li.actions",
            h("label", "Actions"),
            self.renderActions(response.actions)
          ),
          h("li.predicants",
            h("label", "Predicants Issued"),
            self.renderPredicants(response.predicants)
          ),
          self.state.selectedResponse === response
            ? h("div.buttons",
                h("button.remove-response", {onclick: remove}, "Remove")
              )
            : undefined
        )
      ]
    );
  },

  render: function () {
    return r('div', {});
  },

  renderPlastiq: function() {
    var self = this;

    function activeWhen(b) {
      if (b) {
        return undefined;
      } else {
        return "disabled";
      }
    }

    var dirty = self.state.dirty;
    var created = self.state.query.id;
    var activeWhenDirtyAndCreated = activeWhen(dirty && created);
    var dirtyAndCreated = dirty && created;

    function responseMoved(from, to) {
      moveItemInFromTo(self.state.query.responses, from, to);
      self.update();
    }

    return h("div.edit-query",
      h("h2", "Query"),
      h("div.buttons",
        h("button.add-to-clipboard", {onclick: self.addToClipboard}, "Add to Clipboard"),
        created
          ? [
            h("button.insert-query-before",
              {
                class: activeWhenDirtyAndCreated,
                onclick: self.insertBefore
              },
              "Insert Before"
            ),
            h("button.insert-query-after",
              {
                class: activeWhenDirtyAndCreated,
                onclick: self.insertAfter
              },
              "Insert After"
            ),
            h("button.save",
              {
                class: activeWhenDirtyAndCreated,
                onclick: self.save
              },
              "Overwrite"
            ),
            h("button.cancel",
              {
                class: activeWhenDirtyAndCreated,
                onclick: self.cancel
              },
              "Cancel"
            ),
            h("button.delete",
              {
                onclick: self.delete
              },
              "Delete"
            ),
            h("button.close",
              {
                onclick: self.close
              },
              "Close"
            )
          ]
          : [
            h("button.create",
              {
                class: activeWhen(dirty && !created),
                onclick: self.create
              },
              "Create"
            ),
            h("button.cancel",
              {
                class: activeWhen(dirty),
                onclick: self.cancel
              },
              "Cancel"
            ),
            h("button.close",
              {
                onclick: self.close
              },
              "Close"
            )
          ]
      ),
      h("ul",
        h("li.name", { key: "name" },
          h("label", "Name"),
          h("input", { type: "text", binding: [self.state.query, 'name'] })
        ),
        h("li.question", { key: "qtext" },
          h("label", "Question"),
          h("textarea", {
            binding: [self.state.query, 'text']
          })
        ),
        h("li.level", { key: "level" },
          h("label", "Level"),
          self.numberInput(self.state.query, "level")
        ),
        h("li",
          h("label", "Predicants Needed"),
          self.renderPredicants(self.state.query.predicants)
        ),
        h("li.responses",
          h("h3", "Responses"),
          h("button.add", {onclick: self.addResponse}, "Add Response"),
          h('div.response-editor',
            sortable({
              itemMoved: responseMoved,
              render: function () {
                function hide() {
                  self.setState({
                    highlightedResponse: undefined
                  });
                }

                return h('ol.responses',
                  self.state.query.responses.map(function (response) {
                    function select() {
                      self.setState({
                        selectedResponse: response
                      });
                    }

                    function show() {
                      self.setState({
                        highlightedResponse: response
                      });
                    }

                    return h('li', {
                      onclick: select,
                      onmouseenter: show,
                      onmouseleave: hide,
                      class: {selected: self.state.selectedResponse === response}
                    }, response.text);
                  })
                );
              }
            }),
            self.state && self.shownResponse()
              ? h('div.selected-response', self.renderResponse(self.shownResponse()))
              : undefined
          )
        )
      )
    );
  },

  shownResponse: function () {
    return this.state.selectedResponse || this.state.highlightedResponse;
  }
});

function rangeSelect(options) {
  var binding = options.binding;

  return h('h1', 'range select');
}

/*
 * state:
 *  numbers
 *  text
 *  error
 *
 * props:
 *  selectedItems
 *  onChange
 */
var rangeConversion = {
  value: function (text) {
    return _.flatten(text.split(/\s*,\s*/).filter(function (n) {
      return n;
    }).map(function (n) {
      var r = n.split(/\s*-\s*/);

      if (r.length > 1) {
        var low = Number(r[0]), high = Number(r[1]);
        var diff = Math.min(high - low, 1000);
        high = low + diff;
        return _.range(low, high + 1);
      } else {
        return Number(n);
      }
    }));
  },

  text: function (value) {
    if (value) {
      var ranges = [];
      var last;
      var inRange;

      value.forEach(function (n) {
        if (last !== undefined) {
          if (n == last + 1) {
            if (!inRange) {
              ranges.push('-');
              inRange = true;
            }
          } else {
            if (inRange) {
              ranges.push(String(last));
            }
            ranges.push(', ' + String(n));
            inRange = false;
          }
        } else {
          ranges.push(String(n));
        }
        last = n;
      });

      if (inRange) {
        ranges.push(String(last));
      }

      return ranges.join('');
    } else {
      return '';
    }
  }
};

function itemSelect(options) {
  var items = options.items;
  var selectedItems = options.selectedItems;
  var renderItemText = options.renderItemText;
  var placeholder = options.placeholder;

  return h.component(
    {
      onadd: function () {
        this.search = '';
      }
    },
    function (component) {
      var state = component.state;

      state.search = state.search || '';

      function focus() {
        state.show = true;
      }

      function blur(ev) {
        if (!state.activated) {
          state.show = false;
        } else {
          ev.target.focus();
        }
      }

      function activate() {
        state.activated = true;
      }

      function disactivate() {
        state.activated = false;
      }

      function searchKeyDown(ev) {
        if (ev.keyCode === 13) {
          selectItem(matchingItems[0]);
        }
      }

      function selectItem(p) {
        if (selected[p.id]) {
          removeFrom(p.id, selectedItems);
        } else {
          selectedItems.push(p.id);
        }
      }

      function matchesSearch(p, search) {
        if (search === "") {
          return true;
        } else {
          var terms = _.compact(search.toLowerCase().split(/ +/));
          return _.all(terms, function(t) {
            return p.name && p.name.toLowerCase().indexOf(t) >= 0;
          });
        }
      }

      function renderMatchingItem(p) {
        function select() {
          return selectItem(p);
        }

        var text = renderItemText
          ? renderItemText(p)
          : p.name;

        return h("li", {onclick: select},
          h("span", text),
          selected[p.id]
            ? h.rawHtml("span.selected", "&#x2713;")
            : undefined
        );
      }

      var selected = index(selectedItems);
      var matchingItems = Object.keys(items).map(function (k) {
        return items[k];
      }).filter(function (p) {
        return matchesSearch(p, state.search);
      });

      return h("div.item-select",
        {
          onmousedown: activate,
          onmouseup: disactivate
        },
        h("input",
          {
            type: "text",
            placeholder: placeholder,
            binding: [state, 'search'],
            onkeydown: searchKeyDown,
            onblur: blur,
            onfocus: focus
          }
        ),
        h("div.select-list",
          h("ol", {class: {show: state.show}}, matchingItems.map(renderMatchingItem))
        )
      );
    }
  );
}

function block(b) {
  return b();
}

function removeFrom(item, array) {
  var i = array.indexOf(item);
  if (i >= 0) {
    return array.splice(i, 1);
  }
}

function index(array) {
  var obj = {};
  for (var n = 0; n < array.length; ++n) {
    obj[array[n]] = true;
  }
  return obj;
}

module.exports.create = function(obj) {
  var self = this;
  return _.extend({
    responses: [],
    predicants: [],
    level: 1
  }, obj);
};
