var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var moment = require('moment');
var sync = require('./sync');

module.exports = prototype({
  constructor: function (options) {
    var self = this;

    this.documentApi = options.documentApi;
    this.root = options.root;

    this.syncDocuments = sync({
      throttle: 5000,
      condition: function () { return options.user; }
    }, function () {
      return self.documentApi.allDocuments().then(function (documents) {
        self.documents = documents;
      });
    });

    this.syncHasCurrentDocument = sync({
      throttle: 5000,
      condition: function () { return options.user && !self.hasCurrentDocument; }
    }, function () {
      return self.documentApi.currentDocument().then(function (doc) {
        self.hasCurrentDocument = !!doc;
      });
    });
  },

  refresh: function () {},

  createDocument: function () {
    var self = this;

    return this.documentApi.create().then(function (doc) {
      self.root.openDocument(doc);
    });
  },

  loadCurrentDocument: function () {
    var self = this;

    return self.documentApi.currentDocument().then(function (doc) {
      self.root.openDocument(doc);
    });
  },

  loadDocument: function (id) {
    var self = this;

    return this.documentApi.document(id).then(function (doc) {
      self.root.openDocument(doc);
    });
  },

  formatDocumentDate: function (doc) {
    return moment(doc.lastModified).format('LL');
  },

  formatDocumentTitle: function (doc) {
    return [h('.ui.label', this.formatDocumentDate(doc)), doc.name];
  },

  render: function () {
    var self = this;

    this.refresh = h.refresh;

    return h('.documents',
      this.syncHasCurrentDocument(),
      this.syncDocuments(),
      h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Start new document'),
      h('.ui.basic.button', {class: {disabled: !this.hasCurrentDocument}, onclick: self.loadCurrentDocument.bind(self)}, 'Load current document'),
      semanticUi.dropdown(
        {
          onChange: function (value, text) {
            return self.loadDocument(value);
          },
          fullTextSearch: true
        },
        h('.ui.search.selection.dropdown.select-document',
          h('input.search', {tabIndex: '0'}),
          h('.default.text', 'Select document'),
          h('.menu', {tabIndex: '-1'},
            self.documents? self.documents.map(function (doc) {
              return h('.item', {dataset: {value: doc.id}}, self.formatDocumentTitle(doc));
            }): undefined
          )
        )
      )
    )
  }
});
