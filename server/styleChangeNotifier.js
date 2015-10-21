var documentHasChangedStyles = require('./documentHasChangedStyles');
var sendEmail = require('./sendEmail');
var debug = require('debug')('lexenotes:style-change-notification');
var diff = require('diff');
var routes = require('../browser/routes');
var emailTemplates = require('./emailTemplates');
var urlUtils = require('url');

function StyleChangeNotifier(options) {
  this.smtpUrl = options.smtpUrl;
  this.systemEmail = options.systemEmail || 'Lexetech System <system@lexetech.com>';
  this.adminEmail = options.adminEmail || 'Lexetech Admin <admin@lexetech.com>';
  this.db = options.db;
  this.user = options.user;
  this.baseUrl = options.baseUrl;
}

StyleChangeNotifier.prototype.notifyOnStyleChange = function(document, originalDocument) {
  var self = this;

  var updatedLexemes = documentHasChangedStyles(document, originalDocument);

  if (updatedLexemes) {
    if (this.smtpUrl) {
      return this.lexemeDifferences(updatedLexemes).then(function (lexemeDifferences) {
        return sendEmail(self.smtpUrl, {
          from: self.systemEmail,
          to: self.adminEmail,
          subject: 'response change',
          template: 'styleChangeNotification',
          data: lexemeDifferences
        });
      });
    }
  }
};

StyleChangeNotifier.prototype.lexemeDifferences = function(updatedLexemes) {
  var self = this;

  return Promise.all(updatedLexemes.map(function (updatedLexeme) {
    debug('queryId', updatedLexeme.queryId);
    return self.db.queryById(updatedLexeme.queryId).then(function(query) {
      var response = query.responses.filter(function (response) {
        return response.id == updatedLexeme.responseId;
      })[0];

      if (response) {
        var styleDifferences = Object.keys(updatedLexeme.styles).map(function (style) {
          var diffs = diff.diffWords(response.styles[style], updatedLexeme.styles[style]);

          return {style: style, diffs: diffs};
        });

        query.authoringHref = urlUtils.resolve(self.baseUrl, routes.authoringQuery({blockId: query.block, queryId: query.id}).href);

        return {
          query: query,
          response: response,
          styles: styleDifferences
        };
      }
    });
  })).then(function (allLexemeDifferences) {
    self.user.adminHref = urlUtils.resolve(self.baseUrl, routes.adminUser({userId: self.user.id}).href);

    return {
      user: self.user,
      lexemes: allLexemeDifferences.filter(function (x) { return x; })
    };
  });
};

module.exports = function (smtpUrl) {
  return new StyleChangeNotifier(smtpUrl);
}
