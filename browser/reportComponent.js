var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var _ = require('underscore');

var queryComponent = require('./queryComponent');
var debugComponent = require('./debugComponent');
var documentComponent = require('./documentComponent');
var historyComponent = require('./history');

function dirtyBinding(model, name) {
  return {
    get: function () { return model[name]; },
    set: function (value) { model[name] = value; model.dirty = true; }
  };
}

module.exports = prototype({
  constructor: function (options) {
    var self = this;

    this.document = options.document;
    this.documentComponent = documentComponent(this);

    this.debug = debugComponent({
      currentQuery: function () {
        return self.history.query;
      },
      lexemeApi: options.lexemeApi
    });

    this.history = historyComponent({
      document: options.document,
      queryGraph: options.queryGraph,
      setQuery: function (query) {
        self.query.setQuery(query);
      }
    });

    this.query = queryComponent({
      user: options.user,
      history: this.history,
      debug: this.debug
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

    if (this.document.dirty) {
      this.throttledSaveDocument();
    }

    return h('div.report',
      h('.left',
        h('.report-header.ui.form',
          h('.field',
            h('label', 'Report Identifier'),
            h('.ui.icon.input', {class: {loading: this.document.dirty}},
              h('input', {type: 'text', placeholder: 'Name', binding: dirtyBinding(this.document, 'name')}),
              h('i.icon')
            )
          )
        ),
        self.query.render()
      ),
      h('.right',
        semanticUi.tabs(
          h('.ui.top.attached.tabular.menu',
            h('a.item.active', {dataset: {tab: 'document'}}, 'Document'),
            h('a.item.debug', {dataset: {tab: 'debug'}}, 'Debug')
          )
        ),
        h('.ui.bottom.attached.tab.segment.active', {dataset: {tab: 'document'}},
          self.documentComponent.render()
        ),
        h('.ui.bottom.attached.tab.segment', {dataset: {tab: 'debug'}},
          self.debug.render()
        )
      )
    );
  }
});
