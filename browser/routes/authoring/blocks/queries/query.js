var Promise = require("bluebird");
var self = this;
var React = require("react");
var r = React.createElement;
var ReactRouter = require("react-router");
var Navigation = ReactRouter.Navigation;
var _ = require("underscore");
var sortable = require("../sortable");
var moveItemInFromTo = require("../moveItemInFromTo");
var blockName = require("../blockName");
var responseHtmlEditor = require("../../responseHtmlEditor");
var reactBootstrap = require("react-bootstrap");
var DropdownButton = reactBootstrap.DropdownButton;
var MenuItem = reactBootstrap.MenuItem;

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

    return r("div", {},
      r("ol", {},
        actions.map(function (action) {
          function remove() {
            removeAction(action);
          }
          return self.renderAction(action, remove);
        })
      ),
      r(DropdownButton, { title: "Add Action" },
        !hasRepeat && !hasSetOrAddBlocks
          ? r(MenuItem, {
              onClick: addActionClick(function() {
                return {
                  name: "setBlocks",
                  arguments: []
                };
              })
            }, "Set Blocks")
          : undefined,

        !hasRepeat && !hasSetOrAddBlocks
          ? r(MenuItem, {
              onClick: addActionClick(function() {
                return {
                  name: "addBlocks",
                  arguments: []
                };
              })
            }, "Add Blocks")
          : undefined,

        r(MenuItem,
          {
            onClick: addActionClick(function() {
              return {
                name: "repeatLexeme",
                arguments: []
              };
            })
          },
          "Repeat"
        ),
        r(MenuItem,
          {
            onClick: addActionClick(function() {
              return {
                name: "setVariable",
                arguments: [ "", "" ]
              };
            })
          },
          "Set Variable"
        ),
        r(MenuItem,
          {
            onClick: addActionClick(function() {
              return {
                name: "suppressPunctuation",
                arguments: []
              };
            })
          },
          "Suppress Punctuation"
        ),
        r(MenuItem,
          {
            onClick: addActionClick(function() {
              return {
                name: "loadFromFile",
                arguments: []
              };
            })
          },
          "Load from File"
        ),
        r(MenuItem,
          {
            onClick: addActionClick(function() {
              return {
                name: "loopBack",
                arguments: []
              };
            })
          },
          "Loop Back"
        )
      )
    );
  },

  renderAction: function(action, removeAction) {
      var self = this;
      var renderAction;

      function removeButton() {
          return r("div", {
              className: "buttons"
          }, r("button", {
              className: "remove-action",
              onClick: removeAction
          }, "Remove"));
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

            return r("li", {},
              r("span", {}, blockName(b)),
              r("button",
                {
                  className: "remove-block remove",
                  onClick: remove,
                  dangerouslySetInnerHTML: {
                    __html: "&cross;"
                  }
                }
              )
            );
          });

          return r("ol", {}, args);
        }

        function itemMoved(from, to) {
          moveItemInFromTo(action.arguments, from, to);
          self.update();
        }

        return r('li', {className: $class},
          [r('h4', {}, name)].concat(
            self.state.blocks
              ? [
                  React.createElement(rangeSelect, {
                    onChange: setArguments,
                    selectedItems: action.arguments,
                    items: self.state.blocks
                  }),
                  React.createElement(sortable,
                    {
                      itemMoved: itemMoved,
                      render: renderArguments
                    }
                  ),
                  React.createElement(itemSelect,
                    {
                      onAdd: addBlock,
                      onRemove: removeBlock,
                      selectedItems: action.arguments,
                      items: self.state.blocks,
                      renderItemText: blockName,
                      placeholder: "add block"
                    }
                  )
                ]
              : undefined
          ).concat([removeButton()])
        );
      }

      renderAction = {
        setBlocks: function(action) {
          return blocks("Set Blocks", "action-set-blocks");
        },

        addBlocks: function(action) {
          return blocks("Add Blocks", "action-add-blocks");
        },

        setVariable: function(action) {
          return r("li", {},
            r("h4", {},
              "Set Variable"
            ),
            r("ul", {},
              r("li", {},
                r("label", {}, "Name"),
                r("input",
                  {
                    type: "text",
                    onChange: self.bind(action.arguments, 0),
                    value: self.textValue(action.arguments[0])
                  }
                )
              ),
              r("li", {},
                r("label", {}, "Value"),
                r("input",
                  {
                    type: "text",
                    onChange: self.bind(action.arguments, 1),
                    value: self.textValue(action.arguments[1])
                  }
                )
              )
            ),
            removeButton()
          );
        },

        repeatLexeme: function(action) {
          return r("li", {},
            r("h4", {}, "Repeat Lexeme"),
            removeButton()
          );
        },

        suppressPunctuation: function(action) {
          return r("li", {},
            r("h4", {}, "Suppress Punctuation"),
            removeButton()
          );
        },

        loadFromFile: function(action) {
          return r("li", {},
            r("h4", {}, "Load from File"),
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

        return r("li", {},
          r("span", {}, p.name),
          r("button",
            {
              className: "remove-predicant remove",
              onClick: remove,
              dangerouslySetInnerHTML: {
                  __html: "&cross;"
              }
            }
          )
        );
      }

      return r("div", {className: "predicants"},
        r("ol", {}, predicants.map(renderPredicant)),
        r(itemSelect, {
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
    return r("input",
      {
        type: "number",
        onChange: this.bind(model, field, Number),
        value: model[field],
        onFocus: function(ev) {
          return $(ev.target).on("mousewheel.disableScroll", function(ev) {
            ev.preventDefault();
          });
        },
        onBlur: function(ev) {
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
        return React.createElement(responseHtmlEditor, { className: 'editor', onChange: self.bindHtml(response.styles, style), value: self.textValue(response.styles[style]) });
      } else {
        return r('div', {className: 'editor', dangerouslySetInnerHTML: {__html: response.styles[style] }});
      }
    }

    return r("li", { key: response.id },
      [
        editing
          ? r("div", {className: "buttons top"},
              r("button", {className: "close", onClick: deselect}, "Close")
            )
          : undefined,
        r("ul", {},
          r("li", {className: "selector"},
            r("label", {}, "Selector"),
            r("textarea", {onChange: self.bind(response, "text"), value: self.textValue(response.text), onFocus: select})
          ),
          r("li", {className: "set-level"},
            r("label", {}, "Set Level"),
            self.numberInput(response, "setLevel")
          ),
          r("li", {className: "style1"},
            r("label", {}, "Style 1"),
            renderStyle('style1')
          ),
          r("li", {className: "style2"},
            r("label", {}, "Style 2"),
            renderStyle('style2')
          ),
          r("li", {className: "actions"},
            r("label", {}, "Actions"),
            self.renderActions(response.actions)
          ),
          r("li", {className: "predicants"},
            r("label", {}, "Predicants Issued"),
            self.renderPredicants(response.predicants)
          ),
          self.state.selectedResponse === response
            ? r("div", {className: "buttons"},
                r("button", {className: "remove-response", onClick: remove}, "Remove")
              )
            : undefined
        )
      ]
    );
  },

  render: function() {
    var self = this;

    function activeWhen(b) {
        if (b) {
            return "";
        } else {
            return " disabled";
        }
    }

    var dirty = self.state.dirty;
    var created = self.state.query.id;
    var activeWhenDirtyAndCreated = activeWhen(dirty && created);

    function responseMoved(from, to) {
      moveItemInFromTo(self.state.query.responses, from, to);
      self.update();
    }

    return r("div", {className: "edit-query"},
      r("h2", {}, "Query"),
      r("div", {className: "buttons"},
        r("button", {className: "add-to-clipboard", onClick: self.addToClipboard}, "Add to Clipboard"),
        created
          ? [
            r("button",
              {
                className: "insert-query-before" + activeWhenDirtyAndCreated,
                onClick: self.insertBefore
              },
              "Insert Before"
            ),
            r("button",
              {
                className: "insert-query-after" + activeWhenDirtyAndCreated,
                onClick: self.insertAfter
              },
              "Insert After"
            ),
            r("button",
              {
                className: "save" + activeWhenDirtyAndCreated,
                onClick: self.save
              },
              "Overwrite"
            ),
            r("button",
              {
                className: "cancel" + activeWhen(dirty),
                onClick: self.cancel
              },
              "Cancel"
            ),
            r("button",
              {
                className: "delete",
                onClick: self.delete
              },
              "Delete"
            ),
            r("button",
              {
                className: "close",
                onClick: self.close
              },
              "Close"
            )
          ]
          : [
            r("button",
              {
                className: "create" + activeWhen(dirty && !created),
                onClick: self.create
              },
              "Create"
            ),
            r("button",
              {
                className: "cancel" + activeWhen(dirty),
                onClick: self.cancel
              },
              "Cancel"
            ),
            r("button",
              {
                className: "close",
                onClick: self.close
              },
              "Close"
            )
          ]
      ),
      r("ul", {},
        r("li", { key: "name", className: "name" },
          r("label", {}, "Name"),
          r("input", { type: "text", onChange: self.bind(self.state.query, "name"), value: self.textValue(self.state.query.name) })
        ),
        r("li", { key: "qtext", className: "question" },
          r("label", {}, "Question"),
          r("textarea", {
            onChange: self.bind(self.state.query, "text"),
            value: self.textValue(self.state.query.text)
          })
        ),
        r("li",
          {
            key: "level",
            className: "level"
          },
          r("label", {}, "Level"),
          self.numberInput(self.state.query, "level")
        ),
        r("li", {},
          r("label", {}, "Predicants Needed"),
          self.renderPredicants(self.state.query.predicants)
        ),
        r("li", {className: "responses"},
          r("h3", {}, "Responses"),
          r("button", {className: "add", onClick: self.addResponse}, "Add Response"),
          r('div', {className: 'response-editor'},
            React.createElement(sortable,
              {
                itemMoved: responseMoved,
                render: function () {
                  function hide() {
                    self.setState({
                      highlightedResponse: undefined
                    });
                  }

                  return r('ol', {className: "responses"},
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

                      return r('li', {
                        onClick: select,
                        onMouseEnter: show,
                        onMouseLeave: hide,
                        className: self.state.selectedResponse === response? 'selected': undefined
                      }, response.text);
                    })
                  );
                }
              }
            ),
            self.state && self.shownResponse()
              ? r('div', {className: 'selected-response'}, self.renderResponse(self.shownResponse()))
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

var rangeSelect = React.createClass({
  getInitialState: function () {
    return {
      numbers: []
    };
  },

  componentDidMount: function () {
    this.setState({
      numbers: this.props.selectedItems.map(function (n) { return Number(n); })
    });
  },

  componentWillReceiveProps: function (nextProps) {
    this.setState({
      numbers: nextProps.selectedItems.map(function (n) { return Number(n); })
    });
  },

  generateRanges: function (numbers) {
    if (numbers) {
      var ranges = [];
      var last;
      var inRange;

      numbers.forEach(function (n) {
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
  },

  parseNumbers: function (text) {
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

  numbersText: function () {
    var modelValue = this.state.numbers;
    if (this.state.error) {
      return this.state.text;
    } else if (this.state.text === undefined) {
      var modelText = this.generateRanges(modelValue);
      this.state.text = modelText;
      return modelText;
    } else {
      var previousValue = this.parseNumbers(this.state.text);
      var modelText = this.generateRanges(modelValue);
      var normalisedPreviousText = this.generateRanges(previousValue);

      if (modelText === normalisedPreviousText) {
        return this.state.text;
      } else {
        this.state.text = modelText;
        return modelText;
      }
    }
  },

  textChange: function (ev) {
    var text = ev.target.value;

    try {
      var numbers = this.parseNumbers(text);
      this.props.onChange(numbers.map(function (x) { return String(x); }));
      this.setState({
        error: undefined,
        text: text,
        numbers: numbers
      });
    } catch (e) {
      this.setState({
        error: e,
        text: text
      });
    }
  },

  render: function () {
    return r('input', {onChange: this.textChange, type: 'text', value: this.numbersText()});
  }
});

var itemSelect = React.createClass({
  getInitialState: function() {
    return {
      search: "",
      show: false
    };
  },

  searchChange: function(ev) {
    return this.setState({
      search: ev.target.value
    });
  },

  focus: function() {
    return this.setState({
      show: true
    });
  },

  blur: function(ev) {
    if (!this.state.activated) {
      return this.setState({
        show: false
      });
    } else {
      return ev.target.focus();
    }
  },

  activate: function() {
    return this.setState({
      activated: true
    });
  },

  disactivate: function() {
    return this.setState({
      activated: false
    });
  },

  render: function() {
    var self = this;

    function matchesSearch(p, search) {
      if (self.search === "") {
        return true;
      } else {
        var terms = _.compact(search.toLowerCase().split(/ +/));
        return _.all(terms, function(t) {
          return p.name && p.name.toLowerCase().indexOf(t) >= 0;
        });
      }
    }

    var selected = index(self.props.selectedItems);
    var matchingItems = Object.keys(self.props.items).map(function (k) {
      return self.props.items[k];
    }).filter(function (p) {
      return matchesSearch(p, self.state.search);
    });

    function selectItem(p) {
      if (selected[p.id]) {
        return self.props.onRemove(p);
      } else {
        return self.props.onAdd(p);
      }
    }

    function searchKeyDown(ev) {
      if (ev.keyCode === 13) {
        return selectItem(matchingItems[0]);
      }
    }

    function renderMatchingItem(p) {
      function select() {
        return selectItem(p);
      }

      var text = self.props.renderItemText
        ? self.props.renderItemText(p)
        : p.name;

      return r("li", {onClick: select},
        r("span", {}, text),
        selected[p.id]
          ? r("span", { className: "selected", dangerouslySetInnerHTML: { __html: "&#x2713;" } })
          : undefined
      );
    }

    return r("div",
      {
        className: "item-select",
        onMouseDown: self.activate,
        onMouseUp: self.disactivate,
        onBlur: self.blur,
        onFocus: self.focus
      },
      r("input",
        {
          type: "text",
          placeholder: self.props.placeholder,
          onChange: self.searchChange,
          onKeyDown: searchKeyDown,
          value: self.state.search
        }
      ),
      r("div", {className: "select-list"},
        r("ol", {className: self.state.show? "show": ""}, matchingItems.map(renderMatchingItem))
      )
    );
  }
});

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
