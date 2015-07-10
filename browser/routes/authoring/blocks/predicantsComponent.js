var h = require('plastiq').html;
var semanticUi = require('plastiq-semantic-ui');
var loadPredicants = require('./loadPredicants');
var _ = require('underscore');
var throttle = require('plastiq-throttle');
var http = require('../../../http');
var clone = require('./queries/clone');
var routes = require('../../../routes');

function PredicantsComponent(options) {
  var self = this;

  this.onclose = options.onclose;

  this.predicants = options.predicants;
  this.filteredPredicants = [];

  this.predicants.load().then(function () {
    self.refresh();
  });

  this.selectPredicant = throttle({throttle: 0}, this.selectPredicant.bind(this));

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

PredicantsComponent.prototype.refresh = function () {
  console.log("refreshing, but haven't rendered yet!");
};

PredicantsComponent.prototype.loadQueriesForSelectedPredicant = function () {
  var self = this;

  self.usagesForSelectedPredicant = {
    queries: [],
    responses: []
  };

  return http.get('/api/predicants/' + this.selectedPredicant.id + '/usages').then(function (usages) {
    self.usagesForSelectedPredicant = usages;
    self.refresh();
  });
};

PredicantsComponent.prototype.selectPredicant = function(id) {
  var predicant = this.predicants.predicantsById[id];
  if (predicant) {
    this.originalSelectedPredicant = predicant;
    this.selectedPredicant = clone(predicant);
    this.loadQueriesForSelectedPredicant(predicant);
  }
};

PredicantsComponent.prototype.render = function () {
  var self = this;

  this.refresh = h.refresh;

  this.search(this.query, this.predicants.loaded);

  return h('.predicants-editor',
    routes.authoringPredicants(function () {
      return self.renderPredicantsList();
    }),
    routes.authoringPredicant(function (params) {
      self.selectPredicant(params.predicantId, self.predicants.loaded);

      return [
        self.renderPredicantsList(),
        self.selectedPredicant
          ? self.renderPredicantEditor()
          : undefined
      ];
    })
  );
};

PredicantsComponent.prototype.renderPredicantsList = function () {
  return h('.predicant-search',
    h('.ui.button',
      {
        onclick: function () {
          routes.authoringPredicant({predicantId: 'create'}).push();
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
        return h('a.item.teal',
          {
            href: '#',
            class: {active: predicant == self.originalSelectedPredicant},
            onclick: function (ev) {
              routes.authoringPredicant({predicantId: predicant.id}).push();
              ev.preventDefault();
            }
          },
          h('h5', predicant.name)
        );
      })
    )
  );
};

PredicantsComponent.prototype.renderPredicantEditor = function () {
  var self = this;

  return h('.selected-predicant',
    h('h1', 'Predicant'),
    h('.ui.input',
      h('input.name', {type: 'text', binding: h.binding([self.selectedPredicant, 'name'], {refresh: false})})
    ),
    h('.buttons',
      self.selectedPredicant.id
      ? h('button.save.ui.button.blue', {
          onclick: function () {
            return http.put(self.selectedPredicant.href, self.selectedPredicant).then(function () {
              self.originalSelectedPredicant.name = self.selectedPredicant.name;
              delete self.selectedPredicant;
              routes.authoringPredicants().push();
            });
          }
        }, 'Save')
      : h('button.create.ui.button.green', {
          onclick: function () {
            return http.post('/api/predicants', self.selectedPredicant).then(function (predicant) {
              self.predicants.addPredicant(predicant);
              self.search.reset();
              delete self.selectedPredicant;
              routes.authoringPredicants().push();
            });
          }
        }, 'Create'),
      h('button.close.ui.button', {
        onclick: function () {
          delete self.selectedPredicant;
          routes.authoringPredicants().push();
        }
      }, 'Close')
    ),
    h('.predicant-usages',
      self.usagesForSelectedPredicant.queries.length
        ? h('.predicant-usages-queries',
            h('h3', 'Depenent Queries'),
            h('.ui.vertical.menu.results',
              self.usagesForSelectedPredicant.queries.map(function (query) {
                return h('.item.teal', h('.header', routes.authoringQuery({blockId: query.block, queryId: query.id}).link(query.name)));
              })
            )
          )
        : undefined,
      self.usagesForSelectedPredicant.responses.length
        ? h('.predicant-usages-responses',
            h('h3', 'Issuing Responses'),
            h('.ui.vertical.menu.results',
              self.usagesForSelectedPredicant.responses.map(function (responseQuery) {
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
            )
          )
        : undefined
    )
  );
};

module.exports = function (options) {
  return new PredicantsComponent(options);
};
