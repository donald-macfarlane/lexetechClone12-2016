var _ = require("underscore");

module.exports = function(document, originalDocument) {
  if (!document.lexemes) {
    return false;
  }

  function lexemeHasChangedStyles(lexeme, originalLexeme) {
    var styles = lexeme.response.styles;
    var changedStyles = lexeme.response.changedStyles;
    var originalStyles = originalLexeme && originalLexeme.response.styles;

    var differentStyles = {};
    var hasDifferences = false;

    Object.keys(styles).forEach(function (key) {
      if(changedStyles[key] && (!originalStyles || originalStyles[key] !== styles[key])) {
        hasDifferences = true;
        differentStyles[key] = styles[key];
      }
    });

    if (hasDifferences) {
      return {
        queryId: lexeme.query.id,
        responseId: lexeme.response.id,
        styles: differentStyles
      };
    }
  }

  function findOriginalLexeme(queryId, responseId) {
    return _.find(originalDocument.lexemes, function (lexeme) {
      return lexeme.query.id == queryId && lexeme.response.id == responseId;
    });
  }

  if (originalDocument) {
    return prepareDifferences(document.lexemes.map(function (lexeme) {
      var originalLexeme = findOriginalLexeme(lexeme.query.id, lexeme.response.id);
      return lexemeHasChangedStyles(lexeme, originalLexeme);
    }));
  } else {
    return prepareDifferences(document.lexemes.map(function (lexeme) {
      return lexemeHasChangedStyles(lexeme);
    }));
  }
};

function prepareDifferences(allDifferences) {
  var differences = allDifferences.filter(function (x) { return x; });

  if (differences.length > 0) {
    return differences;
  } else {
    return false;
  }
}
