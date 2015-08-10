var _ = require('underscore');
var removeFromArray = require('../../../removeFromArray');
var http = require('../../../http');

function Predicants() {
  this.predicants = [];
  this.predicantsById = {};
}

Predicants.prototype.load = function() {
  if (!(this.loaded || this.loading)) {
    var self = this;

    this.loading = true;
    return this.loadingPromise = Promise.all([
      http.get("/api/predicants"),
      http.get("/api/users", {suppressErrors: true}).then(undefined, function (error) {
        // user doesn't have admin access to see users
        // don't show users
        if (error.status != 403) {
          throw error;
        }
      })
    ]).then(function(results) {
      var predicants = results[0];
      var users = results[1];

      if (users) {
        users.forEach(function (user) {
          var id = 'user:' + user.id;
          var name = user.firstName + ' ' + user.familyName;
          predicants[id] = {
            id: id,
            name: name
          };
        });
      }

      self.predicantsById = predicants;
      self.predicants = _.values(predicants);
      self.loaded = true;
      delete self.loading;
    });
  } else {
    return this.loadingPromise;
  }
};

Predicants.prototype.addPredicant = function(predicant) {
  this.predicants.push(predicant);
  this.predicantsById[predicant.id] = predicant;
}

Predicants.prototype.removePredicant = function(predicant) {
  removeFromArray(predicant, this.predicants);
  delete this.predicantsById[predicant.id];
}

Predicants.prototype.reload = function () {
  if (this.loading) {
    var self = this;
    this.loading.then(function () {
      self.reload();
    });
  } else {
    this.loaded = false;
    this.load();
  }
};

module.exports = function () {
  return new Predicants();
};
