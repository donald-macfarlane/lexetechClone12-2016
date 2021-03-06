var plastiq = require('plastiq');
var h = plastiq.html;
var buildGraph = require('./buildGraph');
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var responseEditor = require('./responseEditorComponent');
var join = require('./join');

var queryComponent = prototype({
  constructor: function (model) {
    var self = this;
    this.user = model.user;
    this.history = model.history;
    this.queryGraph = buildGraph({cache: false});

    this.responseEditor = responseEditor({
      selectResponse: this.selectResponse.bind(this),
      documentStyle: model.documentStyle,
      history: model.history
    });

    if (this.user) {
      this.history.currentQuery().then(function (query) {
        self.setQuery(query);
        self.refresh();
      });
    }
  },

  setQuery: function (query) {
    this.responseEditor.stopEditingResponse();
    this.responseEditor.stopShowingResponse();
  },

  selectResponse: function (response, _styles) {
    var self = this;
    var styles = _styles || this.history.stylesForQueryResponse(response);

    return this.history.selectResponse(response, styles).query.then(function (q) {
      self.setQuery(q);
    });
  },

  selectedResponse: function () {
    return this.responseEditor.selectedResponse();
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
      var checkedResponses = self.history.checkedResponses(query) || {};
      var lexemeToAccept = self.history.lexemeToAccept();

      var selectedResponse = lexemeToAccept && lexemeToAccept.response !== undefined && query.responses && query.responses.filter(function (r) {
        return r.id == lexemeToAccept.response.id;
      })[0];

      function renderButton(content, _class, onclick, enabled) {
        enabled = arguments.length === 3? true: enabled;

        _class.disabled = !enabled;

        return h('.ui.button',
          {
            class: _class,
            onclick: enabled? onclick: undefined
          },
          content
        );
      }

      return [
        h('h3.query-text', {key: 'query-text', class: {finished: !query.query}}, query.query? query.query.text: 'finished'),
        renderButton(join('accept', h('br')), {accept: true}, self.history.accept.bind(self.history), lexemeToAccept),
        self.responseEditor.render(),
        h('.query',
          h('.buttons',
            renderButton('undo', {undo: true}, self.undo.bind(self), self.history.canUndo()),
            renderButton('omit', {omit: true, selected: lexemeToAccept && lexemeToAccept.omit}, self.omit.bind(self)),
            renderButton('skip', {skip: true, selected: lexemeToAccept && lexemeToAccept.skip}, self.skip.bind(self))
          ),
          query.query
            ? h('div.ui.selection.list.responses', {class: {overflow: query.responses.length >= 10}},
                query.responses.map(function (response) {
                  return h('div.item.response',
                    {
                      class: {
                        selected: selectedResponse == response,
                        loading: self.loadingResponse == response,
                        checked: checkedResponses[response.id],
                        editing: self.responseEditor.editing() == response
                      },
                      onmouseenter: function () {
                        self.responseEditor.showResponse(response);
                      },
                      onmouseleave: function () {
                        self.responseEditor.stopShowingResponse();
                      },
                      onclick: function (ev) {
                        ev.preventDefault();
                        return self.selectResponse(response);
                      }
                    },
                    h('a.content',
                      {
                        href: '#',
                        onclick: function (ev) {
                          ev.preventDefault();
                          ev.stopPropagation();
                          return self.selectResponse(response);
                        }
                      },
                      response.text
                    ),
                    h('button.edit-response',
                      {
                        onclick: function (ev) {
                          ev.stopPropagation();
                          ev.preventDefault();
                          self.responseEditor.editResponse(response);
                        }
                      },
                      'edit'
                    )
                  );
                })
              )
            : undefined
        )
      ];
    }
  }
});

module.exports = queryComponent;
