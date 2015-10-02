var prototype = require('prote');
var http = require('./http');
var cache = require('../common/cache');
var entity = require('./entity');
var updateObject = require('./updateObject');

function identityMap(options) {
  var idField = options && options.hasOwnProperty('id') && options.id !== undefined? options.id: 'id';
  var constructor = options && options.hasOwnProperty('constructor') && options.constructor !== undefined? options.constructor: function (x) { return x; };
  var onChange = options && options.hasOwnProperty('onChange') && options.onChange !== undefined? options.onChange: function () {};

  var entities = {};

  var id =
    typeof idField === 'function'
    ? id
    : function (entity) {
      return entity[idField || 'id'];
    }

  function create(entity) {
    var entityId = id(entity);
    var existing = entities[entityId];

    if (existing) {
      updateObject(existing, entity);
      return existing;
    } else {
      return entities[id(entity)] = constructor(entity);
    }
  };

  create.add = function (entity) {
    entities[id(entity)] = entity;
    onChange();
    return entity;
  };

  create.delete = function (entity) {
    delete entities[id(entity)];
    onChange();
    return entity;
  };

  return create;
}

function event() {
  var listeners = [];

  function emit() {
    var args = arguments;
    listeners.forEach(function (listener) {
      listener.apply(undefined, args);
    });
  }

  emit.on = function (listener) {
    listeners.push(listener);
  };

  emit.off = function (listener) {
    var i = listeners.indexOf(listener);
    if (i >= 0) {
      return listeners.splice(i, 1);
    }
  };

  return emit;
}

module.exports = prototype({
  constructor: function () {
    this.userPrototype = prototype.extending(entity, {
      collectionHref: '/api/users'
    });
    var self = this;
    this.changed = event();
    this.mapUser = identityMap({constructor: this.userPrototype, onChange: this.changed});
    this.userPrototype.prototype.identityMap = this.mapUser;
  },

  users: function (params) {
    var self = this;
    return http.get('/api/users', {params: params}).then(function (response) {
      return response.body.map(self.mapUser);
    });
  },

  search: function(query) {
    var self = this;
    return http.get('/api/users/search', {querystring: {q: query}}).then(function (response) {
      return response.body.map(self.mapUser);
    });
  },

  user: function (userId) {
    var self = this;
    return http.get('/api/users/' + userId).then(function (response) {
      return self.mapUser(response.body);
    });
  },

  create: function () {
    return this.userPrototype.apply(undefined, arguments);
  },

  resetPasswordToken: function (user) {
    return http.post(user.resetPasswordTokenHref).then(function (r) {
      return r.body;
    });
  },

  deleteUser: function (user) {
    var self = this;

    return http.delete(user.href).then(function () {
      self.mapUser.delete(user);
    });
  }
});
