var plastiq = require('plastiq');
var prototype = require('prote');
var routism = require('routism');

function associativeArrayToObject(array) {
  var o = {};

  array.forEach(function (item) {
    o[item[0]] = item[1];
  });

  return o;
}

module.exports = prototype({
  constructor: function (options) {
    this.routes = [];
    this.history = options.history;
  },

  route: function (pattern, params) {
    function isBinding(params) {
      return params && typeof(params.get) == 'function' && typeof(params.set) == 'function';
    }

    function isBindingArray(params) {
      return params instanceof Array;
    }

    function routeBinding(params) {
      if (isBinding(params)) {
        return params;
      } else if (isBindingArray(params)) {
        return plastiq.binding(params);
      } else {
        var binding = (function () {
          var b = {};

          Object.keys(params).forEach(function (paramName) {
            var param = params[paramName];
            b[paramName] = routeBinding(param);
          });

          return b;
        })();

        return {
          get: function () {
            var o = {};
            Object.keys(binding).forEach(function (paramName) {
              o[paramName] = binding[paramName].get();
            });

            return o;
          },
          set: function (value) {
            Object.keys(binding).forEach(function (paramName) {
              binding[paramName].set(value[paramName]);
            });
          }
        }
      }
    }
    if (isBinding(params) || isBindingArray(params)) {
      var binding = routeBinding(params);
      this.routes.push({
        pattern: pattern,
        route: {
          active: function () {
            return binding.get();
          },
          binding: binding,
          url: function (pattern, params) {
            return pattern;
          }
        }
      });
    } else if (params) {
      var binding = routeBinding(params);
      this.routes.push({
        pattern: pattern,
        route: {
          active: function () {
            var value = binding.get();

            return Object.keys(value).every(function (key) {
              return value[key] !== undefined;
            });
          },
          binding: binding,
          url: function (pattern, params) {
            return pattern.replace(/:([a-z_][a-z0-9_]*)/gi, function (_, id) {
              return params[id];
            });
          }
        }
      });
    } else {
      this.routes.push({
        pattern: pattern,
        route: {
          active: function () { return true; },
          binding: {get: function () {}, set: function () {}},
          url: function (pattern, params) {
            return pattern;
          }
        }
      });
    }
  },

  setModel: function(path) {
    var routes = routism.compile(this.routes);
    var route = routes.recognise(path);

    if (route) {
      console.log('route', route);
      var params = associativeArrayToObject(route.params);
      console.log('params', params);
      route.route.binding.set(params);
    }
  },

  getRoute: function() {
    for(var n = 0; n < this.routes.length; n++) {
      var route = this.routes[n];

      console.log('testing', route.pattern);
      if (route.route.active()) {
        console.log('active', route.pattern);
        return route.route.url(route.pattern, route.route.binding.get());
      }
    }
  },

  location: function (location) {
    var currentPath = location.pathname + location.search;
    console.log('last', this.lastPath, 'current', currentPath);
    
    if (this.lastPath === undefined || currentPath !== this.lastPath) {
      this.lastPath = currentPath;
      return this.setModel(currentPath);
    } else {
      var newPath = this.getRoute();
      this.lastPath = newPath;

      if (currentPath !== newPath) {
        this.history.push(newPath);
      }
    }
  }
});
