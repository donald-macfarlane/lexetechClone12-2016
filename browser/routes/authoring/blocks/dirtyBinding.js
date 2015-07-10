var h = require('plastiq').html;

module.exports = function (entity) {
  return function (model, property) {
    var args = new Array(arguments.length);
    for (var n = 0; n < arguments.length; n++) {
      args[n] = arguments[n];
    }
    var binding = h.binding.call(h, args);

    return {
      get: binding.get,
      set: function (value) {
        entity._dirty = true;
        binding.set(value);
      }
    };
  };
};
