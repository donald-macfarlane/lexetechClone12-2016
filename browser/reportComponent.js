var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var _ = require('underscore');
var queryComponent = require('./queryComponent');
var debugComponent = require('./debugComponent');
var documentComponent = require('./documentComponent');
var createHistory = require('./history');
var routes = require('./routes');
var zeroClipboard = require('plastiq-zeroclipboard');
var vdomToHtml = require('vdom-to-html');
var wait = require('./wait');

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

    function refresh() {
      if (self.refresh) {
        self.refresh();
      }
    }

    this.history = createHistory({
      document: options.document,
      queryGraph: options.queryGraph,
      setQuery: setQuery,
      refresh: refresh,
      lexemeApi: options.lexemeApi
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
          zeroClipboard(
            {
              oncopy: function () {
                var self = this;
                self.copied = true;
                return wait(1000).then(function () {
                  self.copied = false;
                });
              },
              onerror: function (e) {
                this.noFlash = true;
                self.selectDocument();
                this.noFlashMessage = true;
                return wait(1000).then(function () {
                  this.noFlashMessage = false;
                });
              }
            },
            {
              'text/plain': function () {
                var html = vdomToHtml(self.documentComponent.render(self.documentStyle.style));
                var element = document.createElement('div');
                element.innerHTML = html;
                return element.innerText;
              },
              'text/html': function () {
                return vdomToHtml(self.documentComponent.render(self.documentStyle.style));
              }
            },
            function () {
              if (this.noFlash) {
                return h(
                  '.ui.button',
                  {
                    onclick: function () {
                      self.selectDocument();
                    }
                  },
                  'Select All'
                );
              } else {
                return h('.ui.button', {class: {copied: this.copied}}, this.copied? 'Copied!': 'Copy');
              }
            }
          ),
          h('.ui.button', { 
            onclick: function() {self.print()}},
            'Print'),
          h('.ui.button', 'Discard')
        ])
      )
    );
  },

  selectDocument: function () {
    var doc = document.querySelector('.document');
    var range = document.createRange();
    range.selectNode(doc);
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
  },

  print: function () {
    location.href = routes.printReport({documentId: this.document.id, style: this.documentStyle.style}).href;
  },

  renderPrint: function () {
    return this.documentComponent.render(this.documentStyle.style);
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
        )
      )
    });

    return reportNameComponent;
  }
});
