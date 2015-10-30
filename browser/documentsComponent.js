var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var moment = require('moment');
var throttle = require('plastiq-throttle');
var debug = require('debug')('start-enote');
var removeFromArray = require('./removeFromArray');
var _ = require('underscore');
var routes = require('./routes');

module.exports = prototype({
  constructor: function (options) {
    this.user = options.user;
    this.documentApi = options.documentApi;
    this.root = options.root;
  },

  refresh: function () {},

  loadDocuments: function() {
    var self = this;
    if (self.user) {
      return self.documentApi.allDocuments().then(function (documents) {
        self.documents = documents;
      });
    }
  },

  createDocument: function () {
    var self = this;

    return this.documentApi.create().then(function (doc) {
      routes.enote({documentId: doc.id}).push();
    });
  },

  askToDeleteDocument: function (doc) {
    var self = this;
    return new Promise(function (fulfil) {
      self.askToDeleteModal = true;
      self.documentToDelete = doc;
      self.tellDeleteDocument = function (goAheadWithDelete) {
        delete self.askToDeleteModal;
        delete self.tellDeleteDocument;
        fulfil(goAheadWithDelete);
      };
    });
  },

  loadDocument: function (id) {
    routes.enote({documentId: id}).push();
  },

  deleteDocument: function (docToDelete) {
    var self = this;

    return self.askToDeleteDocument(docToDelete).then(function (goAheadWithDelete) {
      if (goAheadWithDelete) {
        return self.documentApi.delete(docToDelete.id).then(function () {
          self.documents = self.documents.filter(function (doc) {
            return doc.id != docToDelete.id;
          });
        });
      }
    });
  },

  renderDocumentList: function () {
    var self = this;
    this.refresh = h.refresh;

    return h('div.your-documents',
      h('h1', 'Your documents'),
      h('table.table.ui.celled.documents',
        h('thead',
          h('tr',
            h('th', {colspan: 4},
              h('.ui.right.floated.button', {onclick: self.createDocument.bind(self)}, 'New Document')
            )
          ),
          h('tr',
            h('th', 'Name'),
            h('th', 'Created'),
            h('th', 'Modified'),
            h.rawHtml('th', '&nbsp;')
          )
        ),
        h('tbody',
          self.documents.map(function (doc) {
            return h('tr.button.document', {onclick: function() {return self.loadDocument(doc.id)}},
              h('td.name', documentName(doc)),
              h('td',moment(doc.created).format('LLL')),
              h('td',moment(doc.lastModified).format('LLL')),
              h('td', h('.ui.button.delete', {onclick: function (ev) { ev.stopPropagation(); return self.deleteDocument(doc); }}, 'delete'))
            )
          })
        )
      ),
      self.askToDeleteModal
        ? semanticUi.modal(
            {
              onApprove: function () {
                self.tellDeleteDocument(true);
              },

              onDeny: function () {
                self.tellDeleteDocument(false);
              },

              onHide: function () {
                if (self.tellDeleteDocument) {
                  self.tellDeleteDocument(false);
                }
              }
            },
            h('.ui.modal',
              h('.header', 'Are you sure you want to delete ' + documentName(self.documentToDelete) + '?'),
              h('.actions', h('.ui.button.ok', 'Ok'), h('.ui.button.cancel', 'Cancel'))
            )
          )
        : undefined
    )
  },

  renderGetStarted: function() {
    var self = this;
    return h('div.no-documents',
      h('h1', 'Your documents'),
      h('p', 'You have not yet created any documents.'),
      h('p', 
        h('a', {href: '#tutorial'}, 'Read the tutorial'),
        ' or start a new document when you are ready:'
      ),
      h('.ui.button.new-document', {onclick: self.createDocument.bind(self)}, 'New Document')
    );
  },

  render: function () {
    var self = this;
    this.refresh = h.refresh;

    return h('.documents',
      self.documents
        ? self.documents.length > 0
          ? self.renderDocumentList()
          : self.renderGetStarted() 
        : h('.ui.active.inverted.dimmer.loading', h('.ui.text.loader', 'loading'))
    );
  },
});

function documentName(document) {
  return document.name || 'Untitled';
}
