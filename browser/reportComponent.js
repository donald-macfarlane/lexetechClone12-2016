var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var _ = require('underscore');

var queryComponent = require('./queryComponent');
var debugComponent = require('./debugComponent');
var documentComponent = require('./documentComponent');
var historyComponent = require('./history');

function dirtyBinding(model, name, component) {
  return {
    get: function () {
      return model[name];
    },
    set: function (value) {
      model[name] = value;
      model.dirty = true;
      return component;
    }
  };
}

module.exports = prototype({
  constructor: function (options) {
    var self = this;

    this.document = options.document;

    this.debug = debugComponent({
      currentQuery: function () {
        return self.history.query;
      },
      lexemeApi: options.lexemeApi,
      selectedResponse: function () {
        return self.query.selectedResponse();
      },
      variables: function () {
        return self.history.variables();
      }
    });

    function setQuery (query) {
      self.query.setQuery(query);
    }

    this.history = historyComponent({
      document: options.document,
      queryGraph: options.queryGraph,
      setQuery: setQuery
    });

    this.documentStyle = {
      style: 'style1'
    };

    this.query = queryComponent({
      user: options.user,
      history: this.history,
      debug: this.debug,
      documentStyle: this.documentStyle
    });

    this.documentComponent = documentComponent({
      history: this.history,
      query: this.query,
      documentStyle: this.documentStyle,
      setQuery: setQuery
    });
  },

  currentQuery: function () {
    return this.query.query;
  },

  throttledSaveDocument: _.throttle(function () {
    var self = this;

    delete this.document.dirty;
    this.document.update().then(function () {
      self.refresh();
    });
  }, 500, {leading: false}),

  render: function () {
    var self = this;
    this.refresh = h.refresh;

    return h('div.report',
      h('link', {rel: 'stylesheet', href: '/report.css'}),
      self.renderReportName(),
      h('.query-response-editor',
        self.query.render()
      ),
      h('.document-tabs',
        semanticUi.tabs(
          '.ui.top.attached.tabular.menu',
          {
            binding: [self.documentStyle, 'style'],
            tabs: [
              {
                key: 'style1',
                tab: h('a.item.style-normal', 'Normal'),
                content: function (key) {
                  return h('.ui.bottom.attached.tab.segment', self.documentComponent.render(key));
                }
              },
              {
                key: 'style2',
                tab: h('a.item.style-abbreviated', 'Abbreviated'),
                content: function (key) {
                  return h('.ui.bottom.attached.tab.segment', self.documentComponent.render(key));
                }
              },
              {
                key: 'debug',
                tab: h('a.item.debug', 'Debug'),
                content: function (key) {
                  return h('.ui.bottom.attached.tab.segment', self.debug.render());
                }
              }
            ]
          }
        ),
        h('.actions', [
          h('.ui.button', { 
            onclick: function() {window.print()}},
            'Print'),
          h('.ui.button', 'Discard')
        ])
      )
    );
  },

  renderReportName: function () {
    var self = this;

    var reportNameComponent = h.component(function () {
      if (self.document.dirty) {
        self.throttledSaveDocument();
      }

      return h('.field.inline.document-name',
        h('label', 'Document Name'),
        h('.ui.icon.right.labeled.input', {class: {loading: self.document.dirty}},
          h('input.report-name', {type: 'text', placeholder: 'Untitled', binding: dirtyBinding(self.document, 'name', reportNameComponent)}),
          h('.ui.green.label', self.document.dirty? 'saving...': 'saved')
          // h('i.icon'),
        )
      )
    });

    return reportNameComponent;
  }
});
