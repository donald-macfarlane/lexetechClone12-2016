var prototype = require('prote');
var _ = require('underscore');

module.exports = prototype({
  key: function() {
    if (this._key) {
      return this._key;
    } else {
      var key = JSON.stringify({
        ci: this.coherenceIndex,
        b: this.block,
        bs: Object.keys(this.blocks),
        l: this.level,
        p: this.predicants,
        bss: this.blockStack,
        lp: this.loopPredicants
      });

      Object.defineProperty(this, '_key', { value: key });
      return key;
    }
  },

  pushBlockStack: function() {
    return this.blockStack.unshift({
      coherenceIndex: this.coherenceIndex,
      block: this.block,
      blocks: this.blocks
    });
  },

  predicantsForLevel: function (level) {
    var hasLoopPredicants = this.loopPredicants.filter(function (x) { return x; }).length > 0;

    if (hasLoopPredicants) {
      var preds = {};

      _.extend(preds, this.predicants);
      this.loopPredicants.forEach(function (loopPredicants, index) {
        if (level <= index + 1) {
          _.extend(preds, loopPredicants);
        }
      });

      return preds;
    } else {
      return this.predicants;
    }
  },

  popBlockStack: function() {
    var b = this.blockStack.shift();
    this.coherenceIndex = b.coherenceIndex;
    this.block = b.block;
    this.blocks = b.blocks;
  },

  parkLoopPredicants: function (queryLevel, loopHeadIndex) {
    var self = this;

    var loopHeadLevel = queryLevel - 1;
    self.loopPredicants = self.loopPredicants || [];
    var loopPredicants = self.loopPredicants[loopHeadLevel - 1] = self.loopPredicants[loopHeadLevel - 1] || {};

    Object.keys(self.predicants).map(function (key) {
      var historyIndex = self.predicants[key];

      if (historyIndex > loopHeadIndex) {
        delete self.predicants[key];
        loopPredicants[key] = historyIndex;
      }
    });

    self.looping = true;
  },

  restoreLoopPredicants: function (queryLevel) {
    if (this.looping) {
      delete this.looping;
    } else if (this.loopPredicants) {
      for(var n = queryLevel - 1; n < this.loopPredicants.length; n++) {
        _.extend(this.predicants, this.loopPredicants[n]);
      }

      this.loopPredicants.splice(queryLevel - 1);
    }
  }
});
