var prototype = require('prote');
var updateObject = require('./updateObject');
var http = require('./http');

module.exports = prototype({
  save: function (update) {
    var self = this;

    if (this.original) {
      return this.original.save(this);
    } else {
      if (update) {
        updateObject(this, update);
        delete this.original;
      }
      if (this.href) {
        return http.put(this.href, this);
      } else if (this.collectionHref) {
        return http.post(this.collectionHref, this).then(function (result) {
          if (result.id) {
            self.id = result.id;
          }

          if (result.href) {
            self.href = result.href;
          }

          if (self.identityMap) {
            return self.identityMap.add(self);
          } else {
            return self;
          }
        });
      }
    }
  },

  edit: function () {
    var clone = this.constructor(JSON.parse(JSON.stringify(this)));
    clone.original = this;
    return clone;
  }
});
