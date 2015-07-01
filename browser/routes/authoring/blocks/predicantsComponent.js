var h = require('plastiq').html;
var semanticUi = require('plastiq-semantic-ui');
var loadPredicants = require('./loadPredicants');
var _ = require('underscore');
var throttle = require('plastiq-throttle');
var http = require('../../../http');
var clone = require('./queries/clone');

function PredicantsComponent(options) {
  var self = this;

  this.onclose = options.onclose;

  this.predicants = options.predicants;
  this.filteredPredicants = [];

  this.predicants.load().then(function () {
    self.refresh();
  });

  this.search = throttle(function (query) {
    if (query) {
      var lowerCaseQuery = query.toLowerCase();
      this.filteredPredicants = this.predicants.predicants.filter(function (predicant) {
        return predicant.name.toLowerCase().indexOf(lowerCaseQuery) >= 0;
      });
    } else {
      this.filteredPredicants = this.predicants.predicants;
    }
  });
}

PredicantsComponent.prototype.refresh = function () {};

PredicantsComponent.prototype.render = function () {
  var self = this;

  this.refresh = h.refresh;

  this.search(this.query);

  function selectPredicant(predicant) {
    self.originalSelectedPredicant = predicant;
    self.selectedPredicant = clone(predicant);
  }

  return semanticUi.modal(
    {
      onHidden: function () {
        self.onclose();
      }
    },
    h('.ui.modal',
      h('i.close.icon'),
      h('.header', 'Predicants'),
      h('.content',
        h('.predicants-editor',
          h('.predicant-search',
            h('.ui.button',
              {
                onclick: function () {
                  self.selectedPredicant = {};
                }
              },
              'Create'
            ),
            h('.ui.icon.input',
              h('input', {type: 'text', placeholder: 'search predicants', binding: [this, 'query']}),
              h('i.search.icon')
            ),
            h('.ui.vertical.menu.results',
              this.filteredPredicants.map(function (predicant) {
                return h('a',
                  {
                    href: '#',
                    onclick: function (ev) {
                      selectPredicant(predicant);
                      ev.preventDefault();
                    }
                  },
                  h('h5', predicant.name)
                );
              })
            )
          ),
          self.selectedPredicant
            ? h('.selected-predicant',
                h('h1', 'Predicant'),
                h('input', {type: 'text', binding: [self.selectedPredicant, 'name']}),
                h('.buttons',
                  self.selectedPredicant.id
                  ? h('.ui.button.blue', {
                      onclick: function () {
                        return http.put(self.selectedPredicant.href, self.selectedPredicant).then(function () {
                          self.originalSelectedPredicant.name = self.selectedPredicant.name;
                          delete self.selectedPredicant;
                        });
                      }
                    }, 'Save')
                  : h('.ui.button.green', {
                      onclick: function () {
                        return http.post('/api/predicants', self.selectedPredicant).then(function (predicant) {
                          delete self.selectedPredicant;
                          self.predicants.addPredicant(predicant);
                        });
                      }
                    }, 'Create'),
                  h('.ui.button', {
                    onclick: function () {
                      delete self.selectedPredicant;
                    }
                  }, 'Close'),
                  h('.ui.button.red', {
                    onclick: function () {
                      return http.delete(self.selectedPredicant.href).then(function () {
                        self.predicants.removePredicant(self.originalSelectedPredicant);
                        delete self.selectedPredicant;
                        self.search.reset();
                      });
                    }
                  }, 'Delete')
                )
              )
            : undefined
        )
      )
    )
  );
};

module.exports = function (options) {
  return new PredicantsComponent(options);
};
