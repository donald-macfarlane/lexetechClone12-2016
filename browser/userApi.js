var prototype = require('prote');
var http = require('./http');
var cache = require('../common/cache');

function identityMap(options) {
  var idField = options && options.hasOwnProperty('id') && options.id !== undefined? options.id: 'id';
  var constructor = options && options.hasOwnProperty('constructor') && options.constructor !== undefined? options.constructor: function (x) { return x; };

  var entities = {};

  var id =
    typeof idField === 'function'
    ? id
    : function (entity) {
      return entity[idField || 'id'];
    }

  return function(entity) {
    var entityId = id(entity);
    var existing = entities[entityId];

    if (existing) {
      updateObject(existing, entity);
      return existing;
    } else {
      return entities[entityId] = constructor(entity);
    }
  };
}

function updateObject(existing, entity) {
  Object.keys(existing).forEach(function (k) {
    delete existing[k];
  });

  Object.keys(entity).forEach(function (k) {
    existing[k] = entity[k];
  });
}

var userPrototype = prototype({
  update: function (update) {
    if (this.original) {
      return this.original.update(this);
    } else {
      if (update) {
        updateObject(this, update);
        delete this.original;
      }
      return http.put(this.href, this);
    }
  },
  edit: function () {
    var clone = userPrototype(JSON.parse(JSON.stringify(this)));
    clone.original = this;
    return clone;
  }
});

var user = identityMap({constructor: userPrototype});

module.exports = prototype({
  constructor: function () {
  },

  users: function (params) {
    return http.get('/api/users', {params: params}).then(function (users) {
      return users.map(user);
    });
  },

  search: function(query) {
    return http.get('/api/users/search', {params: {q: query}}).then(function (users) {
      return users.map(user);
    });
  },

  user: function (userId) {
    return http.get('/api/users/' + userId).then(user);
  }
});
