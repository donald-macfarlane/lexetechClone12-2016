var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var moment = require('moment');

module.exports = prototype({
  constructor: function (options) {
    var self = this;

    this.documentsApi = options.documentsApi;
    this.root = options.root;

    this.documentsApi.allDocuments().then(function (documents) {
      self.documents = documents;
      self.refresh();
    });

    this.documentsApi.currentDocument().then(function (doc) {
      self.currentDocument = doc;
      self.refresh();
    });
  },

  refresh: function () {},

  createDocument: function () {
    var self = this;

    return this.documentsApi.create().then(function (doc) {
      self.root.openDocument(doc);
    });
  },

  loadCurrentDocument: function () {
    this.root.openDocument(this.currentDocument);
  },

  loadDocument: function (id) {
    var self = this;

    return this.documentsApi.document(id).then(function (doc) {
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
      h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Start new document'),
      h('.ui.basic.button', { onclick: self.loadCurrentDocument.bind(self) }, 'Load current document'),
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
