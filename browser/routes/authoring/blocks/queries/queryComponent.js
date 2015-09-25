var http = require('../../http');
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
var removeFromArray = require('../../../../removeFromArray');
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
  this.blocks = options.blocks;

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
      return h.rawHtml('div.editor', response.styles[style] || '&nbsp;');
    }
  }

  return h(".field", { key: response.id },
    [
      editing
        ? h("div.buttons",
            h("button.ui.button.close", {onclick: deselect}, "Close"),
            h("button.ui.button.remove-response", {onclick: remove}, "Remove")
          )
        : undefined,
      h(".form",
        h(".field.selector",
          h("label", "Selector"),
          h('.ui.input',
            h("input", {type: 'text', binding: self.dirtyBinding(response, 'text'), onfocus: select})
          )
        ),
        h(".field.set-level",
          h("label", "Set Level"),
          self.numberInput(response, "setLevel")
        ),
        h(".field.style1",
          h("label", "Style 1"),
          renderStyle('style1')
        ),
        h(".field.style2",
          h("label", "Style 2"),
          renderStyle('style2')
        ),
        h(".field.actions",
          h("label", "Actions"),
          self.renderActions(response.actions)
        ),
        h(".field.predicants",
          h("label", "Predicants Issued"),
          self.renderPredicants(response.predicants)
        )
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

  return h(".edit-query.ui.segment",
    h("h2", "Query"),
    h("div.buttons",
      h("button.ui.button.add-to-clipboard", {onclick: self.addToClipboard.bind(self)}, "Add to Clipboard"),
      created
        ? [
          h("button.ui.button.insert-query-before",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.insertBefore.bind(self)
            },
            "Insert Before"
          ),
          h("button.ui.button.insert-query-after",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.insertAfter.bind(self)
            },
            "Insert After"
          ),
          h("button.ui.button.save.blue",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.save.bind(self)
            },
            "Overwrite"
          ),
          h("button.ui.button.cancel.red",
            {
              class: activeWhenDirtyAndCreated,
              onclick: self.cancel.bind(self)
            },
            "Cancel"
          ),
          h("button.ui.button.delete.red",
            {
              onclick: self.delete.bind(self)
            },
            "Delete"
          ),
          h("button.ui.button.close",
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
          h("button.ui.button.close",
            {
              onclick: self.close.bind(self)
            },
            "Close"
          )
        ]
    ),
    h(".ui.form",
      h('.two.fields',
        h(".field.name", { key: "name" },
          h("label", "Name"),
          h('.ui.input',
            h("input", { type: "text", binding: self.dirtyBinding(self.query, 'name') })
          )
        ),
        h(".field.level", { key: "level" },
          h("label", "Level"),
          self.numberInput(self.query, "level")
        )
      ),
      h(".field.question", { key: "qtext" },
        h("label", "Question"),
        h("textarea", {
          binding: self.dirtyBinding(self.query, 'text')
        })
      ),
      h(".field",
        h("label", "Predicants Needed"),
        h(".two.fields.predicants",
          self.renderPredicants(self.query.predicants)
        )
      ),
      h(".field.responses",
        h("label", "Responses"),
        h("button.ui.button.add", {onclick: self.addResponse.bind(self)}, "Add Response"),
        h('div.response-editor',
          sortable('.ui.vertical.menu.results',
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

              return h('a.item', {
                onclick: select,
                onmouseenter: show,
                onmouseleave: hide,
                class: {active: self.selectedResponse === response}
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

  function addActionClick(actionId, action) {
    return function(ev) {
      addAction({
        name: actionId,
        arguments: action.createArguments && action.createArguments() || []
      });
      ev.preventDefault();
    };
  }

  var existingActionNames = _.indexBy(actions, 'name');

  var hasRepeat = actions.filter(function (a) { return a.name == 'repeatLexeme'; }).length > 0;
  var hasSetOrAddBlocks = actions.filter(function (a) {
    return a.name == 'setBlocks' || a.name == 'addBlocks';
  }).length > 0;

  function actionMenuItem(actionId, action) {
    return menuItem(
      {
        onclick: addActionClick(actionId, action)
      },
      action.name
    );
  }

  var actionDefinitionList = Object.keys(actionDefinitions).map(function (key) {
    return {
      id: key,
      definition: actionDefinitions[key]
    };
  });

  return [
    semanticUi.dropdown(
      h('.ui.floating.dropdown.icon.button',
        h('i.dropdown', 'Add Action'),
        h('.menu',
          actionDefinitionList.filter(function (action) {
            if (!existingActionNames[action.id]) {
              if (action.definition.incompatibleWith) {
                return !action.definition.incompatibleWith.some(function (incompatible) {
                  return existingActionNames[incompatible];
                });
              } else {
                return true;
              }
            }
          }).map(function (action) {
            return actionMenuItem(action.id, action.definition);
          })
        )
      )
    ),
    h(".ui.fluid.vertical.menu",
      actions.map(function (action) {
        function remove() {
          removeAction(action);
        }

        if (action.name != 'none') {
          var actionDefinition = actionDefinitions[action.name];
          return self.renderAction(actionDefinition, action, remove);
        }
      })
    )
  ];
};

function renderBlocksAction(component, action) {
  function setArguments(blockIds) {
    action.arguments.splice(0, action.arguments.length);
    action.arguments.push.apply(action.arguments, blockIds.filter(function (id) { return component.blocks.blocksById[id]; }));
    component.dirty();
  }

  function removeBlock(block) {
    removeFromArray(block.id, action.arguments);
    component.dirty();
  }

  function itemMoved(from, to) {
    moveItemInFromTo(action.arguments, from, to);
    component.dirty();
  }

  var filterBlocksConversion = {
    view: function (numbers) {
      return numbers;
    },

    model: function (numbers) {
      return numbers.filter(function (n) { return component.blocks.blocksById[n]; });
    }
  };

  var numberArray = {
    view: function (numbers) {
      return numbers.map(Number);
    },

    model: function (numbers) {
      return numbers.map(String);
    }
  };

  if (component.blocks.blocksById) {
    return [
      h('.field .input',
        h('input', {type: 'text', placeholder: 'e.g. 1,3,5-10', binding: component.dirtyBinding(action, 'arguments', numberArray, filterBlocksConversion, rangeConversion)})
      ),
      action.arguments.length > 0
      ? h('.field',
          sortable('.ui.menu',
            {
              onitemmoved: function (item, from, to) {
                component.dirty();
              }
            },
            action.arguments,
            function (id) {
              var b = component.blocks.blocksById[id];

              function remove() {
                removeBlock(b);
              }

              return h(".item",
                h("span", blockName(b)),
                h.rawHtml("button.label.red.ui.remove-block.small.remove",
                  { onclick: remove },
                  "&cross;"
                )
              );
            }
          )
        )
      : undefined,
      h('.field',
        itemSelect({
          itemAdded: component.dirty.bind(component),
          itemRemoved: component.dirty.bind(component),
          selectedItems: action.arguments,
          items: component.blocks.blocksById,
          renderItemText: blockName,
          placeholder: "add block"
        })
      )
    ];
  }
}

var actionDefinitions = {
  setBlocks: {
    name: 'Set Blocks',

    incompatibleWith: ['repeatLexeme', 'addBlocks'],

    render: function(component, action) {
      return renderBlocksAction(component, action);
    }
  },

  addBlocks: {
    name: 'Add Blocks',

    incompatibleWith: ['repeatLexeme', 'setBlocks'],

    render: function(component, action) {
      return renderBlocksAction(component, action);
    }
  },

  setVariable: {
    name: 'Set Variable',

    createArguments: function() {
      return ['', ''];
    },

    render: function(component, action) {
      return [
        h(".field",
          h("label", "Name"),
          h(".ui.input input",
            {
              type: "text",
              binding: component.dirtyBinding(action.arguments, 0)
            }
          )
        ),
        h(".field",
          h("label","Value"),
          h(".ui.input input",
            {
              type: "text",
              binding: component.dirtyBinding(action.arguments, 1)
            }
          )
        )
      ];
    }
  },

  repeatLexeme: {
    name: 'Repeat Lexeme',

    incompatibleWith: ['addBlocks', 'setBlocks']
  },

  suppressPunctuation: {
    name: 'Suppress Punctuation'
  },

  loopBack: {
    name: 'Loop Back'
  }
};

QueryComponent.prototype.renderAction = function(actionDefinition, action, removeAction) {
  var self = this;

  function removeActionButton() {
    return h("button.ui.label.red.remove.remove-action", {
      onclick: removeAction
    }, "Remove")
  }

  return h('.item.action-' + action.name.replace(/[A-Z]/g, function (c) { return '-' + c.toLowerCase(); }),
    h('h4.ui.header', actionDefinition.name),
    actionDefinition.render? actionDefinition.render(this, action): undefined,
    removeActionButton()
  );
};

QueryComponent.prototype.renderPredicants = function(predicantIds) {
  var self = this;

  function removePredicant(predicant) {
    removeFromArray(predicant.id, predicantIds);
    self.dirty();
  }

  if (self.predicants.loaded) {
    function renderPredicant(p) {
      function remove(ev) {
        removePredicant(p);
        ev.stopPropagation();
        ev.preventDefault();
      }

      return routes.authoringPredicant({predicantId: p.id}).link({class: 'item'},
        p.name,
        h.rawHtml("button.label.red.ui.remove-predicant.small.remove",
          {
            onclick: remove
          },
          "&cross;"
        )
      );
    }

    var predicants = _.sortBy(predicantIds.map(function (id) {
      return self.predicants.predicantsById[id];
    }), function (p) {
      return p.name.toLowerCase();
    });

    return [
      h('.field',
        itemSelect({
          key: 'predicant-select',
          itemAdded: self.dirty.bind(self),
          itemRemoved: self.dirty.bind(self),
          selectedItems: predicantIds,
          items: self.predicants.predicantsById,
          placeholder: "add predicant"
        })
      ),
      h('.field',
        predicants.length? h(".ui.vertical.menu.results", predicants.map(renderPredicant)): undefined
      )
    ];
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
      type: "text",
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
  routes.authoring().push();
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
