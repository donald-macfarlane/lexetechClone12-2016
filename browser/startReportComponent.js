var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var moment = require('moment');
var throttle = require('plastiq-throttle');
var debug = require('debug')('start-report');

module.exports = prototype({
  constructor: function (options) {
    var self = this;

    this.documentApi = options.documentApi;
    this.root = options.root;
    this.currentDocument = options.currentDocument;

    this.loadDocuments = throttle({throttle: 5000}, function () {
      if (options.user) {
        debug('loading documents');
        return self.documentApi.allDocuments().then(function (documents) {
          self.documents = documents;
        });
      }
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
    this.loadDocuments();

    var currentDocument = this.currentDocument();

    return h('.documents',
      h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Start new document'),
      h('h1', 'Your reports'),
      h('table.table.ui.celled.menu.documents',
        h('thead',
          h('tr',
            h('th', 'Title'),
            h('th', 'Name'),
            h('th', '')
          )
        ),
        h('tbody',
          self.documents? self.documents.map(function (doc) {
            return currentDocument && currentDocument.id === doc.id
            ? undefined
            : h('tr',
              h('td.title',self.formatDocumentTitle(doc)),
              h('td.name', doc.name),
              h('td',
                h('.ui.basic.button.load-document', {onclick: function() {return self.loadDocument(doc.id)}}, 'Load')
              )
            );
          }): undefined
        )
      )
    )
  }
});
