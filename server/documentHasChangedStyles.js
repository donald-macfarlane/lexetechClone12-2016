var _ = require("underscore");

module.exports = function(document, originalDocument) {
  if (!document.lexemes) {
    return false;
  }

  function lexemeHasChangedStyles(lexeme, originalLexeme) {
    var styles = lexeme.response.styles;
    var changedStyles = lexeme.response.changedStyles;
    var originalStyles = originalLexeme && originalLexeme.response.styles;

    return Object.keys(styles).some(function (key) {
      return changedStyles[key] && (!originalStyles || originalStyles[key] !== styles[key]);
    });
  }

  function findOriginalLexeme(queryId, responseId) {
    return _.find(originalDocument.lexemes, function (lexeme) {
      return lexeme.query.id == queryId && lexeme.response.id == responseId;
    });
  }

  function stylesAreDifferent(oldStyles, newStyles) {
    return Object.keys(newStyles).some(function (key) {
      return newStyles[key] !== oldStyles[key];
    });
  }

  if (originalDocument) {
    return document.lexemes.some(function (lexeme) {
      var originalLexeme = findOriginalLexeme(lexeme.query.id, lexeme.response.id);
      return lexemeHasChangedStyles(lexeme, originalLexeme);
    });
  } else {
    return document.lexemes.some(function (lexeme) {
      return lexemeHasChangedStyles(lexeme);
    });
  }
};
