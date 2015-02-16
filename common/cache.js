module.exports = function() {
  var cache = {};

  return {
    cacheBy: function(key, block) {
      var value = cache[key];

      if (!value) {
        return cache[key] = block();
      } else {
        return value;
      }
    },

    onceBy: function(key, block) {
      var value = cache[key];

      if (!value) {
        cache[key] = true;
        return block();
      }
    },

    clear: function() {
      cache = {};
    }
  };
};
