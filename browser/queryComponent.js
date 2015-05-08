var plastiq = require('plastiq');
var h = plastiq.html;
var buildGraph = require('./buildGraph');
var prototype = require('prote');
var http = require('./http');
var mediumEditor = require('plastiq-medium-editor');
var semanticUi = require('plastiq-semantic-ui');

var queryComponent = prototype({
  constructor: function (model) {
    var self = this;
    this.user = model.user;
    this.history = model.history;
    this.documentStyle = model.documentStyle;
    this.queryGraph = buildGraph({cache: false});

    if (this.user) {
      this.history.currentQuery().then(function (query) {
        self.setQuery(query);
        self.refresh();
      });
    }
  },

  setQuery: function (query) {
    this.stopEditingResponse();
    this.stopShowingResponse();
  },

  showResponse: function (response) {
    this.showingResponse = {
      response: response,
      styles: this.history.stylesForQueryResponse(response) || response.styles
    };
  },

  selectedResponse: function () {
    return (this.editingResponse && this.editingResponse.response)
      || (this.showingResponse && this.showingResponse.response);
  },

  stopShowingResponse: function () {
    delete this.showingResponse;
  },

  editResponse: function (response) {
    this.editingResponse = {
      response: response,
      styles:
        this.history.stylesForQueryResponse(response)
          || JSON.parse(JSON.stringify(response.styles))
    };
  },

  stopEditingResponse: function () {
    delete this.editingResponse;
  },

  selectResponse: function (response, styles) {
    var self = this;

    return this.history.selectResponse(response, styles).query.then(function (q) {
      self.setQuery(q);
    });
  },

  skip: function () {
    var self = this;

    return self.history.skip().query.then(function (q) {
      self.setQuery(q);
    });
  },

  omit: function () {
    var self = this;

    return self.history.omit().query.then(function (q) {
      self.setQuery(q);
    });
  },

  refresh: function () {},

  undo: function () {
    var self = this;

    return self.history.undo().query.then(function (q) {
      self.setQuery(q);
    });
  },

  render: function () {
    var query = this.history.query;
    var self = this;

    self.refresh = h.refresh;

    if (query) {
      var responsesForQuery = self.history.responsesForQuery(query) || {others: []};
      var selectedResponse = query.responses && query.responses.filter(function (r) {
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
                  return self.history.accept();
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
                          other: responsesForQuery.others[response.id],
                          editing: self.editingResponse && response == self.editingResponse.response
                        },
                        onmouseenter: function () {
                          self.showResponse(response);
                        },
                        onmouseleave: function () {
                          self.stopShowingResponse();
                        }
                      },
                      h('a',
                        {
                          href: '#',
                          onclick: function (ev) {
                            ev.preventDefault();
                            return self.selectResponse(response, self.history.stylesForQueryResponse(response));
                          }
                        },
                        response.text
                      ),
                      h('button.edit-response',
                        {
                          onclick: function (ev) {
                            self.editResponse(response);
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
        self.renderResponseEditor()
      ];
    }
  },

  renderResponseEditor: function () {
    var self = this;

    function styleTabContents(response, id, options) {
      return h('.ui.tab', {class: 'style-' + id},
        options.editing
        ? [
            mediumEditor({
              class: 'response-text-editor',
              binding: [response.styles, id],

              mediumOptions: {
                buttons: ['bold', 'italic', 'header1', 'header2', 'unorderedlist', 'orderedlist']
              }
            }),

            h('button', {
              onclick: function (ev) {
                var promise = self.selectResponse(response.response, response.styles);
                self.stopEditingResponse();
                return promise;
              }
            }, 'ok'),
            ' ',
            h('button', {
              onclick: function (ev) {
                self.stopEditingResponse();
              }
            }, 'cancel'),
            options.edited
              ? [
                  ' ',
                  h('button', {
                    onclick: function (ev) {
                      response.styles[id] = response.response.styles[id];
                    }
                  }, 'revert')
                ]
              : undefined
          ]
        : h.rawHtml('.response-text', response.styles[id])
      );
    }

    function styleTabs(tabs) {
      function styleEdited(id) {
        return response.response.styles[id] != response.styles[id];
      }

      var response = self.editingResponse || self.showingResponse;

      return [
        semanticUi.tabs(
          '.ui.tabular.menu',
          {
            binding: [self.documentStyle, 'style'],
            tabs: tabs.map(function (tab) {
              return {
                key: tab.id,
                tab: h('a.item.style-' + tab.id, {class: {edited: styleEdited(tab.id)}}, tab.name),
                content: function () {
                  return styleTabContents(
                    response,
                    tab.id,
                    {
                      editing: self.editingResponse,
                      edited: styleEdited(tab.id)
                    }
                  );
                }
              }
            })
          }
        )
      ];
    }

    return h('.response-editor',
      self.showingResponse || self.editingResponse
        ? [
          styleTabs([
            {name: 'Normal', id: 'style1', active: true},
            {name: 'Abbreviated', id: 'style2'}
          ]),
        ]
        : undefined
    )
  }
});

module.exports = queryComponent;
