var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');

var queryComponent = require('./query');
var debugComponent = require('./debug');
var documentComponent = require('./document');
var historyComponent = require('./history');

module.exports = prototype({
  constructor: function (options) {
    var self = this;

    this.document = documentComponent(this);

    this.debug = debugComponent({
      currentQuery: function () {
        return self.query.query;
      },
      lexemeApi: options.lexemeApi
    });

    this.history = historyComponent({document: options.document, queryGraph: options.queryGraph});
    this.query = queryComponent({user: options.user, history: this.history, debug: this.debug});
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
            h('a.item.debug', {dataset: {tab: 'debug'}}, 'Debug')
          )
        ),
        h('.ui.bottom.attached.tab.segment.active', {dataset: {tab: 'document'}},
          self.document.render()
        ),
        h('.ui.bottom.attached.tab.segment', {dataset: {tab: 'debug'}},
          self.debug.render()
        )
      )
    );
  }
});
