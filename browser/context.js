var prototype = require('prote');

module.exports = prototype({
  key: function() {
    if (this._key) {
      return this._key;
    } else {
      return this._key = this.level + ":" + Object.keys(this.blocks).join(",") + ":" + Object.keys(this.predicants).join(",");
    }
  },

  pushBlockStack: function() {
    return this.blockStack.unshift({
      coherenceIndex: this.coherenceIndex,
      block: this.block,
      blocks: this.blocks
    });
  },

  popBlockStack: function() {
    var b = this.blockStack.shift();
    this.coherenceIndex = b.coherenceIndex;
    this.block = b.block;
    this.blocks = b.blocks;
  }
});
