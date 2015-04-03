var plastiq = require('plastiq');
var h = plastiq.html;
var buildGraph = require('./buildGraph');
var prototype = require('prote');
var http = require('./http');
var htmlEditor = require('./htmlEditor');
var semanticUi = require('plastiq-semantic-ui');

var queryComponent = prototype({
  constructor: function (model) {
    var self = this;
    this.user = model.user;
    this.history = model.history;
    this.queryGraph = buildGraph({cache: false});

    if (this.user) {
      this.history.currentQuery().then(function (query) {
        self.setQuery(query);
        self.refresh();
      });
    }

    this.history.on('query', function (query) {
      self.setQuery(query);
      self.refresh();
    });
  },

  setQuery: function (query) {
    this.query = query;
    delete this.editingResponse;
    delete this.showingResponse;
  },

  loadingQuery: function (queryPromise) {
    return loadingTimeout(queryPromise, function (loading) {
      if (loading) {
        self.loadingResponse = response;
        self.refresh();
      } else {
        delete self.loadingResponse;
        self.refresh();
      }
    });
  },

  selectResponse: function (response) {
    var self = this;

    return this.loadingQuery(response.query()).then(function (q) {
      self.history.addQueryResponse(self.query.query, response, self.query.context);
      self.setQuery(q);
    });
  },

  skip: function () {
    var self = this;

    return this.loadingQuery(self.query.skip()).then(function (q) {
      self.history.addQuerySkip(self.query.query, self.query.context);
      self.setQuery(q);
    });
  },

  omit: function () {
    var self = this;

    return this.loadingQuery(self.query.omit()).then(function (q) {
      self.history.addQueryOmit(self.query.query, self.query.context);
      self.setQuery(q);
    });
  },

  refresh: function () {},

  undo: function () {
    this.history.undo();
  },

  render: function () {
    var query = this.query;
    var self = this;

    self.refresh = h.refresh;

    if (query) {
      var responsesForQuery = self.history.responsesForQuery(self.query) || {others: []};
      var selectedResponse = self.query.responses && self.query.responses.filter(function (r) {
        return r.id == responsesForQuery.previous;
      })[0];

      return [
        h('.query',
          h('.buttons',
            h('button.undo',
              {
                class: { enabled: self.history.canUndo() },
                onclick: self.history.canUndo() && self.undo.bind(self)
              },
              'undo'
            ),
            h('button.accept',
              {
                class: {enabled: selectedResponse},
                onclick: selectedResponse? function () {
                  return self.selectResponse(selectedResponse);
                }: undefined
              },
              'accept'
            ),
            h('button.skip.enabled',
              {
                onclick: self.skip.bind(self)
              },
              'skip'
            ),
            h('button.omit.enabled',
              {
                onclick: self.omit.bind(self)
              },
              'omit'
            )
          ),
          query.query
            ? [
                h('h3.query-text', query.query.text),
                h('ul.responses',
                  query.responses.map(function (response) {
                    return h('li.response',
                      {
                        class: {
                          selected: selectedResponse == response,
                          loading: self.loadingResponse == response,
                          other: responsesForQuery.others[response.id]
                        },
                        onmouseenter: function () {
                          self.showingResponse = response;
                        },
                        onmouseleave: function () {
                          delete self.showingResponse;
                        }
                      },
                      h('a',
                        {
                          href: '#',
                          onclick: function (ev) {
                            ev.preventDefault();
                            return self.selectResponse(response);
                          }
                        },
                        response.text
                      ),
                      h('button.edit-response',
                        {
                          onclick: function (ev) {
                            response.styles.custom = response.styles.custom || response.styles.style1;
                            self.editingResponse = response;
                          }
                        },
                        'edit'
                      )
                    );
                  })
                )
              ]
            : h('h3.finished', 'finished')
        ),
        h('.response-editor',
           self.showingResponse || self.editingResponse
            ? [
              semanticUi.tabs(
                h('.ui.tabular.menu',
                  h('a.item.active', {dataset: {tab: 'style1'}}, 'style1'),
                  h('a.item', {dataset: {tab: 'style2'}}, 'style2')
                )
              ),
              h('.ui.tab.active', {dataset: {tab: 'style1'}},
                htmlEditor({
                  class: 'response-text-editor',
                  binding:
                    self.editingResponse
                      ? [self.editingResponse.styles, 'custom']
                      : [self.showingResponse.styles, 'style1']
                })
              ),
              h('.ui.tab', {dataset: {tab: 'style2'}},
                htmlEditor({
                  class: 'response-text-editor',
                  binding:
                    self.editingResponse
                      ? [self.editingResponse.styles, 'custom']
                      : [self.showingResponse.styles, 'style2']
                })
              ),
              self.editingResponse? [
                h('button', {onclick: function (ev) { self.selectResponse(self.editingResponse); delete self.editingResponse; }}, 'ok'),
                ' ',
                h('button', {onclick: function (ev) { delete self.editingResponse; }}, 'cancel')
              ]: undefined
            ]
            : undefined
        )
      ];
    }
  }
});

module.exports = queryComponent;

function loadingTimeout(promise, fn) {
  var loaded = false;
  var loading = false;

  function setLoaded(result) {
    loaded = true;
    if (loading) {
      fn(false);
    }
    return result;
  }

  setTimeout(function () {
    if (!loaded) {
      loading = true;
      fn(true);
    }
  }, 140);

  return promise.then(setLoaded, setLoaded);
}
