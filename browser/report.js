var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');

var queryComponent = require('./query');
var debugComponent = require('./debug');
var documentComponent = require('./document');
var historyComponent = require('./history');

module.exports = prototype({
  constructor: function (model) {
    this.document = documentComponent(this);
    this.debug = debugComponent(this);
    this.history = historyComponent({document: model.document, graphHack: model.graphHack});
    this.query = queryComponent({user: model.user, history: this.history, debug: this.debug});
  },

  currentQuery: function () {
    return this.query.query;
  },

  render: function () {
    var self = this;

    return h('div.report',
      h('.left',
        self.query.render()
      ),
      h('.right',
        semanticUi.tabs(
          h('.ui.top.attached.tabular.menu',
            h('a.item.active', {dataset: {tab: 'document'}}, 'Document'),
            h('a.item.debug', {dataset: {tab: 'debug'}}, 'Debug'),
            h('a.item', {dataset: {tab: 'document-json'}}, 'Document JSON')
          )
        ),
        h('.ui.bottom.attached.tab.segment.active', {dataset: {tab: 'document'}},
          self.document.render()
        ),
        h('.ui.bottom.attached.tab.segment', {dataset: {tab: 'debug'}},
          self.debug.render()
        ),
        h('.ui.bottom.attached.tab.segment', {dataset: {tab: 'document-json'}},
          h('pre code', JSON.stringify(this.history, null, 2))
        )
      )
    );
  }
});
