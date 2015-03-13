var plastiq = require('plastiq');
var h = plastiq.html;
var buildGraph = require('./buildGraph');
var prototype = require('prote');
var http = require('./http');
var htmlEditor = require('./htmlEditor');

var queryComponent = prototype({
  constructor: function (model) {
    var self = this;
    this.model = model;
    this.queryGraph = buildGraph();

    if (model.user) {
      self.queryGraph.firstQueryGraph().then(function (query) {
        self.query = query;
        self.refresh();
      });
    }

    this.model.history.on('query', function (message) {
      self.queryGraph.query(message.queryId, message.context).then(function (query) {
        self.query = query;
        self.refresh();
      });
    });
  },

  selectResponse: function (response) {
    var self = this;

    loadingTimeout(response.query(), function (loading) {
      if (loading) {
        self.loadingResponse = response;
        self.refresh();
      } else {
        delete self.loadingResponse;
        self.refresh();
      }
    }).then(function (q) {
      self.model.history.addQueryResponse(self.query, response);
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
      var selectedResponseId = self.model.history.responseIdForQuery(self.query);
      var selectedResponse = self.query.responses && self.query.responses.filter(function (r) {
        return r.id == selectedResponseId;
      })[0];

      return h(' .query',
        query.query
          ? [
              self.model.history.canUndo()? h('button', {onclick: self.undo.bind(self)}, 'undo'): undefined,
              h('h3.query-text', query.query.text),
              selectedResponse? h('button', {onclick: function () { self.selectResponse(selectedResponse); }}, 'accept'): undefined,
              h('ul.responses',
                query.responses.map(function (response) {
                  return h('li.response',
                    {
                      class: {
                        selected: selectedResponse == response,
                        loading: self.loadingResponse == response
                      }
                    },
                    h('a',
                      {
                        href: '#',
                        onclick: function (ev) {
                          ev.preventDefault();
                          self.selectResponse(response);
                        }
                      },
                      response.text
                    ),
                    self.editingResponse == response
                      ? h('.response-editor',
                          htmlEditor({class: 'response-text-editor', binding: [self.editingResponse.styles, 'style1']}),
                          h('button', {onclick: function (ev) { self.selectResponse(self.editingResponse); delete self.editingResponse; }}, 'ok'),
                          ' ',
                          h('button', {onclick: function (ev) { delete self.editingResponse; }}, 'cancel')
                        )
                      : h('button.edit-response',
                          {
                            onclick: function (ev) {
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
      );
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
