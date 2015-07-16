var Promise = require("bluebird");
var http = require('../../../../http');
var h = require('plastiq').html;
var semanticUi = require('plastiq-semantic-ui');
var rangeConversion = require('./rangeConversion');
var responseHtmlEditor = require("../../../../responseHtmlEditor");
var moveItemInFromTo = require("../moveItemInFromTo");
var blockName = require("../blockName");
var _ = require("underscore");
var itemSelect = require('./itemSelect');
var clone = require('./clone');
var routes = require('../../../../routes');
var removeFromArray = require('./removeFromArray');
var dirtyBinding = require('../dirtyBinding');
var sortable = require('plastiq-sortable');

function menuItem() {
  var args = Array.prototype.slice.call(arguments);
  args.unshift('.item');
  return h.apply(undefined, args);
}

function QueryComponent(options) {
  var self = this;

  this.query = options.query;
  this.originalQuery = options.originalQuery;
  this.props = options.props;
  this.blockId = options.blockId;
  this.predicants = options.predicants;
  this.lastResponseId = 0;

  function loadBlocks() {
    return http.get("/api/blocks").then(function(blockList) {
      return _.indexBy(blockList, "id");
    });
  }

  loadBlocks().then(function (blocks) {
    self.blocks = blocks;
  });

  if (!this.predicants.loaded) {
    this.predicants.load().then(function () {
      self.refresh();
    });
  }

  this.dirtyBinding = dirtyBinding(this);
}

QueryComponent.prototype.pasteQueryFromClipboard = function (query) {
  _.extend(this.query, _.omit(query, "level", "id"));
  this._dirty = true;
};

QueryComponent.prototype.refresh = function () {
};

QueryComponent.prototype.renderResponse = function (response) {
  var self = this;

  function remove() {
    self.query.responses = _.without(self.query.responses, response);
    delete self.selectedResponse;
    return self.dirty();
  }

  function select() {
    self.selectedResponse = response;
  }

  function deselect() {
    delete self.selectedResponse;
  }

  var editing = self.selectedResponse === response;

  function renderStyle(style) {
    if (editing) {
      return responseHtmlEditor({ class: 'editor', binding: self.dirtyBinding(response.styles, style)});
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
          h("textarea", {binding: self.dirtyBinding(response, 'text'), onfocus: select})
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
        self.selectedResponse === response
          ? h("div.buttons",
              h("button.remove-response", {onclick: remove}, "Remove")
            )
          : undefined
      )
    ]
  );
};

QueryComponent.prototype.render = function () {
  var self = this;

  this.refresh = h.refresh;

  function activeWhen(b) {
    if (b) {
      return undefined;
    } else {
      return "disabled";
    }
  }

  var dirty = self._dirty;
  var created = self.query.id;
  var activeWhenDirtyAndCreated = activeWhen(dirty && created);
  var dirtyAndCreated = dirty && created;

  function responseMoved(from, to) {
    moveItemInFromTo(self.query.responses, from, to);
    self.dirty();
  }

  return h("div.edit-query",
    h("h2", "Query"),
    h("div.buttons",
      h("button.add-to-clipboard", {onclick: self.addToClipboard.bind(self)}, "Add to Clipboard"),
      created
        ? [
          h("button.insert-query-before",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.insertBefore.bind(self)
            },
            "Insert Before"
          ),
          h("button.insert-query-after",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.insertAfter.bind(self)
            },
            "Insert After"
          ),
          h("button.save",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.save.bind(self)
            },
            "Overwrite"
          ),
          h("button.cancel",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.cancel.bind(self)
            },
            "Cancel"
          ),
          h("button.delete",
            {
              onclick: self.delete.bind(self)
            },
            "Delete"
          ),
          h("button.close",
            {
              onclick: self.close.bind(self)
            },
            "Close"
          )
        ]
        : [
          h("button.create",
            {
              class: activeWhen(dirty && !created),
              onclick: self.create.bind(self)
            },
            "Create"
          ),
          h("button.cancel",
            {
              class: activeWhen(dirty),
              onclick: self.cancel.bind(self)
            },
            "Cancel"
          ),
          h("button.close",
            {
              onclick: self.close.bind(self)
            },
            "Close"
          )
        ]
    ),
    h("ul",
      h("li.name", { key: "name" },
        h("label", "Name"),
        h("input", { type: "text", binding: self.dirtyBinding(self.query, 'name') })
      ),
      h("li.question", { key: "qtext" },
        h("label", "Question"),
        h("textarea", {
          binding: self.dirtyBinding(self.query, 'text')
        })
      ),
      h("li.level", { key: "level" },
        h("label", "Level"),
        self.numberInput(self.query, "level")
      ),
      h("li",
        h("label", "Predicants Needed"),
        self.renderPredicants(self.query.predicants)
      ),
      h("li.responses",
        h("h3", "Responses"),
        h("button.add", {onclick: self.addResponse.bind(self)}, "Add Response"),
        h('div.response-editor',
          sortable('ol.responses',
            {
              onitemmoved: function (item, from, to) {
                self.dirty();
              }
            },
            self.query.responses,
            function (response) {
              function hide() {
                self.highlightedResponse = undefined;
              }

              function select() {
                self.selectedResponse = response;
              }

              function show() {
                self.highlightedResponse = response;
              }

              return h('li', {
                onclick: select,
                onmouseenter: show,
                onmouseleave: hide,
                class: {selected: self.selectedResponse === response}
              }, response.text);
            }
          ),
          self.shownResponse()
            ? h('div.selected-response', self.renderResponse(self.shownResponse()))
            : undefined
        )
      )
    )
  );
};

QueryComponent.prototype.shownResponse = function () {
  return this.selectedResponse || this.highlightedResponse;
};

QueryComponent.prototype.addResponse = function() {
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

  self.query.responses.push(response);
  self.dirty();
  self.selectedResponse = response;
};

QueryComponent.prototype.renderActions = function(actions) {
  var self = this;
  var hasSetOrAddBlocks;

  function addAction(action) {
    actions.push(action);
    self.dirty();
  }

  function removeAction(action) {
    removeFromArray(action, actions);
    self.dirty();
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
};

QueryComponent.prototype.renderAction = function(action, removeAction) {
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
      action.arguments.push.apply(action.arguments, blockIds.filter(function (id) { return self.blocks[id]; }));
      self.dirty();
    }

    function addBlock(block) {
      action.arguments.push(block.id);
      self.dirty();
    }

    function removeBlock(block) {
      removeFromArray(block.id, action.arguments);
      self.dirty();
    }

    function itemMoved(from, to) {
      moveItemInFromTo(action.arguments, from, to);
      self.dirty();
    }

    var filterBlocksConversion = {
      text: function (numbers) {
        return numbers;
      },

      value: function (numbers) {
        return numbers.filter(function (n) { return self.blocks[n]; });
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
      self.blocks
        ? [
            h('input', {type: 'text', binding: self.dirtyBinding(action, 'arguments', numberArray, filterBlocksConversion, rangeConversion)}),
            sortable('ol',
              {
                onitemmoved: function (item, from, to) {
                  self.dirty();
                }
              },
              action.arguments,
              function (id) {
                var b = self.blocks[id];

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
              }
            ),
            itemSelect({
              onAdd: addBlock,
              onRemove: removeBlock,
              selectedItems: action.arguments,
              items: self.blocks,
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
                binding: self.dirtyBinding(action, 0)
              }
            )
          ),
          h("li",
            h("label","Value"),
            h("input",
              {
                type: "text",
                binding: self.dirtyBinding(action, 1)
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
};

QueryComponent.prototype.renderPredicants = function(predicants) {
  var self = this;

  function addPredicant(predicant) {
    predicants.push(predicant.id);
    self.dirty();
  }

  function removePredicant(predicant) {
    removeFromArray(predicant.id, predicants);
    self.dirty();
  }

  if (self.predicants.loaded) {
    function renderPredicant(id) {
      var p = self.predicants.predicantsById[id];

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
        items: self.predicants.predicantsById,
        placeholder: "add predicant"
      })
    );
  }
};

QueryComponent.prototype.dirty = function(value) {
  this._dirty = true;
  return value;
};

QueryComponent.prototype.clean = function() {
  delete this._dirty;
};

QueryComponent.prototype.save = function() {
  var self = this;

  return self.props.updateQuery(self.query).then(function() {
    return self.clean();
  });
};

QueryComponent.prototype.create = function() {
  var self = this;

  return self.props.createQuery(self.query).then(function() {
    return self.clean();
  });
};

QueryComponent.prototype.delete = function() {
  return this.props.removeQuery(this.query);
};

QueryComponent.prototype.insertBefore = function() {
  var self = this;
  return self.props.insertQueryBefore(self.query).then(function() {
    return self.clean();
  });
};

QueryComponent.prototype.insertAfter = function() {
  var self = this;
  return self.props.insertQueryAfter(self.query).then(function() {
    return self.clean();
  });
};

QueryComponent.prototype.numberInput = function(model, field) {
  return h("input",
    {
      type: "number",
      binding: this.dirtyBinding(model, field, Number),
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
};

QueryComponent.prototype.cancel = function() {
  var self = this;
  var copy = clone(this.originalQuery);
  var selectedResponse =
    this.selectedResponse
      ? copy.responses.filter(function (response) {
        return response.id === self.selectedResponse.id;
      })[0]
      : undefined;

  this.query = copy;
  this.selectedResponse = selectedResponse;
  this.clean();
};

QueryComponent.prototype.close = function() {
  routes.authoringBlock({blockId: this.blockId}).push();
};

QueryComponent.prototype.addToClipboard = function() {
  return this.props.addToClipboard(this.query);
};

QueryComponent.prototype.highestResponseId = function() {
  var self = this;

  if (self.query.responses.length) {
    return _.max(self.query.responses.map(function (r) { return Number(r.id); }));
  } else {
    return 0;
  }
};

module.exports = function (options) {
  return new QueryComponent(options);
};

module.exports.create = function(obj) {
  var self = this;
  return _.extend({
    responses: [],
    predicants: [],
    level: 1
  }, obj);
};
