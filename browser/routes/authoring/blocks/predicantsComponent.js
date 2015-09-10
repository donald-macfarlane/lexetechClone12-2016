var h = require('plastiq').html;
var semanticUi = require('plastiq-semantic-ui');
var loadPredicants = require('./loadPredicants');
var _ = require('underscore');
var throttle = require('plastiq-throttle');
var loader = require('plastiq-loader');
var http = require('../http');
var clone = require('./queries/clone');
var routes = require('../../../routes');

function PredicantsComponent(options) {
  var self = this;

  this.onclose = options.onclose;

  this.predicants = options.predicants;
  this.filteredPredicants = [];

  this.loadPredicants = loader(function () {
    var self = this;

    return this.predicants.load().then(function () {
      return self.predicants;
    });
  });

  this.searchPredicants = loader(function (predicants, query) {
    if (predicants) {
      if (query) {
        var lowerCaseQuery = query.toLowerCase();
        return predicants.predicants.filter(function (predicant) {
          return predicant.name.toLowerCase().indexOf(lowerCaseQuery) >= 0;
        });
      } else {
        return predicants.predicants;
      }
    } else {
      return [];
    }
  });

  this.selectPredicant = loader(function (predicants, id) {
    if (predicants) {
      var predicant = predicants.predicantsById[id];

      if (predicant) {
        return {
          originalPredicant: predicant,
          predicant: clone(predicant)
        }
      }
    }
  });

  this.loadQueriesForSelectedPredicant = loader(function (predicant) {
    return http.get('/api/predicants/' + predicant.id + '/usages').then(function (response) {
      return response.body;
    });
  }, {timeout: 0});
}

PredicantsComponent.prototype.createPredicant = function () {
  this.selectedPredicant = {predicant: {}};
};

PredicantsComponent.prototype.loadPredicant = function (predicantId) {
  this.selectedPredicant = this.selectPredicant(this.loadPredicants(), predicantId);
};

PredicantsComponent.prototype.refresh = function () {
  console.warn("refreshing, but haven't rendered yet!");
};

PredicantsComponent.prototype.renderEditor = function () {
  var self = this;

  this.refresh = h.refresh;

  if (this.selectedPredicant) {
    return self.renderPredicantEditor(self.selectedPredicant);
  }
};

PredicantsComponent.prototype.renderMenu = function () {
  this.refresh = h.refresh;

  var filteredPredicants = this.searchPredicants(this.loadPredicants(), this.query);

  var self = this;

  return h('.predicant-search',
    h('.ui.button',
      {
        onclick: function () {
          routes.authoringPredicant({predicantId: 'create'}).push();
        }
      },
      'Create'
    ),
    h('br'),
    h('.ui.icon.input',
      h('input.search', {type: 'text', placeholder: 'search predicants', binding: [this, 'query']}),
      h('i.search.icon')
    ),
    h('.ui.vertical.menu.secondary.results',
      filteredPredicants.map(function (predicant) {
        var predicantRoute = routes.authoringPredicant({predicantId: predicant.id});
        return h('a.item.teal',
          {
            href: predicantRoute.href,
            class: {active: self.selectedPredicant && self.selectedPredicant.originalPredicant && predicant.id == self.selectedPredicant.originalPredicant.id},
            onclick: function (ev) {
              predicantRoute.push();
              ev.preventDefault();
            }
          },
          h('h5', predicant.name)
        );
      })
    )
  );
};

PredicantsComponent.prototype.renderPredicantEditor = function (selectedPredicant) {
  var self = this;

  var usagesForSelectedPredicant = selectedPredicant.originalPredicant && this.loadQueriesForSelectedPredicant(selectedPredicant.originalPredicant);

  function buttons() {
    return h('.buttons',
      selectedPredicant.predicant.id
      ? h('button.save.ui.button.blue', {
          onclick: function () {
            return http.put(selectedPredicant.predicant.href, selectedPredicant.predicant).then(function () {
              selectedPredicant.originalPredicant.name = selectedPredicant.predicant.name;
              delete self.selectedPredicant;
              routes.authoring().push();
            });
          }
        }, 'Save')
      : h('button.create.ui.button.green', {
          onclick: function () {
            return http.post('/api/predicants', selectedPredicant.predicant).then(function (response) {
              var predicant = response.body;
              self.predicants.addPredicant(predicant);
              self.searchPredicants.reset();
              delete self.selectedPredicant;
              routes.authoring().push();
            });
          }
        }, 'Create'),
      h('button.close.ui.button', {
        onclick: function () {
          delete self.selectedPredicant;
          routes.authoring().push();
        }
      }, 'Close')
    );
  }

  return h('.selected-predicant.ui.segment.form',
    h('h1', 'Predicant'),
    buttons(),
    h('.ui.field',
      h('label', 'Name'),
      h('.ui.input',
        h('input.name', {type: 'text', binding: h.binding([selectedPredicant.predicant, 'name'], {refresh: false})})
      )
    ),
    selectedPredicant.predicant.id
      ? h('.predicant-usages',
          h('.predicant-usages-queries',
            h('h3', 'Dependent Queries'),
            h('.ui.vertical.menu.results',
              usagesForSelectedPredicant && usagesForSelectedPredicant.queries.length
                ? usagesForSelectedPredicant.queries.map(function (query) {
                    return h('.item.teal', routes.authoringQuery({blockId: query.block, queryId: query.id}).link(query.name));
                  })
                : h('.item.teal', 'none')
            )
          ),
          h('.predicant-usages-responses',
            h('h3', 'Issuing Responses'),
            h('.ui.vertical.menu.results',
              usagesForSelectedPredicant && usagesForSelectedPredicant.responses.length
                ? usagesForSelectedPredicant.responses.map(function (responseQuery) {
                    var query = responseQuery.query;
                    return h('.item.teal',
                      h('.header', routes.authoringQuery({blockId: query.block, queryId: query.id}).link(query.name)),
                      h('.menu',
                        responseQuery.responses.map(function (response) {
                          return h('.item.teal', response.text);
                        })
                      )
                    );
                  })
                : h('.item.teal', 'none')
            )
          )
        )
      : undefined
  );
};

module.exports = function (options) {
  return new PredicantsComponent(options);
};
