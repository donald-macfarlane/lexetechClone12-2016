var h = require('plastiq').html;
var buildGraph = require('./buildGraph');
var prototype = require('prote');
var http = require('./http');

var queryComponent = prototype({
  constructor: function (model) {
    var self = this;
    this.model = model;

    if (model.user) {
      buildGraph().firstQueryGraph().then(function (query) {
        self.query = query;
        self.refresh();
      });
    }

    this.model.history.on('query', function (query) {
      self.query = query;
    });
  },

  selectResponse: function (response) {
    var self = this;

    self.model.history.addQueryResponse(self.query, response);
    self.refresh();

    response.query().then(function (q) {
      self.query = q;
      self.refresh();
    });
  },

  refresh: function () {},

  undo: function () {
    this.model.history.undo();
  },

  render: function () {
    var query = this.query;
    var self = this;

    self.refresh = h.refresh;

    if (query) {
      var responseSelected = self.model.history.responseForQuery(self.query);

      return h('.report .query',
        query.query
          ? [
              self.model.history.canUndo()? h('button', {onclick: self.undo.bind(self)}, 'undo'): undefined,
              h('h3.query-text', query.query.text),
              responseSelected? h('button', {onclick: function () { self.selectResponse(responseSelected); }}, 'accept'): undefined,
              h('ul.responses',
                query.responses.map(function (response) {
                  return h('li.response', {class: {selected: responseSelected == response}},
                    h('a',
                      {
                        href: '#',
                        onclick: function (ev) {
                          ev.preventDefault();
                          self.selectResponse(response);
                        }
                      },
                      response.text)
                  );
                })
              )
            ]
          : h('h3.finished', 'finished')
      );
    }
  }
});

module.exports = queryComponent;
