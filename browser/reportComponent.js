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
      lexemeApi: options.lexemeApi
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
      h('.left',
        self.renderReportName(),
        self.query.render()
      ),
      h('.right',
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
        )
      )
    );
  },

  renderReportName: function () {
    var self = this;

    if (this.document.dirty) {
      this.throttledSaveDocument();
    }

    var reportNameComponent = h.component(function () {
      return h('.report-header.ui.form',
        h('.field',
          h('label', 'Report Identifier'),
          h('.ui.icon.input', {class: {loading: self.document.dirty}},
            h('input', {type: 'text', placeholder: 'Name', binding: dirtyBinding(self.document, 'name', reportNameComponent)}),
            h('i.icon')
          )
        )
      )
    });

    return reportNameComponent;
  }
});
