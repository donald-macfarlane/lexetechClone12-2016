var _ = require("underscore");

module.exports = {
  model: function (text) {
    return _.flatten(text.split(/\s*,\s*/).filter(function (n) {
      return n;
    }).map(function (n) {
      var r = n.split(/\s*-\s*/);

      if (r.length > 1) {
        var low = Number(r[0]), high = Number(r[1]);
        var diff = Math.min(high - low, 1000);
        high = low + diff;
        return _.range(low, high + 1);
      } else {
        return Number(n);
      }
    }));
  },

  view: function (value) {
    if (value) {
      var ranges = [];
      var last;
      var inRange;

      value.forEach(function (n) {
        if (last !== undefined) {
          if (n == last + 1) {
            if (!inRange) {
              ranges.push('-');
              inRange = true;
            }
          } else {
            if (inRange) {
              ranges.push(String(last));
            }
            ranges.push(', ' + String(n));
            inRange = false;
          }
        } else {
          ranges.push(String(n));
        }
        last = n;
      });

      if (inRange) {
        ranges.push(String(last));
      }

      return ranges.join('');
    } else {
      return '';
    }
  }
};
