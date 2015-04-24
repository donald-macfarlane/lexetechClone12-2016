var plastiq = require('plastiq');
var h = plastiq.html;

function sync(options, fn) {
  if (typeof options === 'function') {
    fn = options;
    options = {};
  }

  var throttle = options.hasOwnProperty('throttle')? options.throttle: 0;
  var condition = options.hasOwnProperty('condition')? options.condition: undefined;
  var watch = options.hasOwnProperty('watch')? options.watch: undefined;

  if (watch) {
    condition = watchCondition(watch);
  }

  var refreshifiedFn;

  return function() {
    if (condition()) {
      if (!refreshifiedFn) {
        if (throttle) {
          refreshifiedFn = _throttle(h.refreshify(fn), throttle);
        } else {
          refreshifiedFn = h.refreshify(fn);
        }
      }

      refreshifiedFn();
    }
  }
}

module.exports = sync;

function watchCondition(watch) {
  var lastValue;
  var hasValue = false;

  return function () {
    var value = watch();

    if (!hasValue || lastValue !== value) {
      hasValue = true;
      lastValue = value;
      return true;
    }
  }
}

// taken from: https://github.com/jashkenas/underscore/blob/483fc0f559699980442d99ed3ed8376217ccc722/underscore.js#L753-L788
// Returns a function, that, when invoked, will only be triggered at most once
// during a given window of time. Normally, the throttled function will run
// as much as it can, without ever going more than once per `wait` duration;
// but if you'd like to disable the execution on the leading edge, pass
// `{leading: false}`. To disable execution on the trailing edge, ditto.
function _throttle(func, wait, options) {
  var context, args, result;
  var timeout = null;
  var previous = 0;
  if (!options) options = {};
  var later = function() {
    previous = options.leading === false ? 0 : Date.now();
    timeout = null;
    result = func.apply(context, args);
    if (!timeout) context = args = null;
  };
  return function() {
    var now = Date.now();
    if (!previous && options.leading === false) previous = now;
    var remaining = wait - (now - previous);
    context = this;
    args = arguments;
    if (remaining <= 0 || remaining > wait) {
      if (timeout) {
        clearTimeout(timeout);
        timeout = null;
      }
      previous = now;
      result = func.apply(context, args);
      if (!timeout) context = args = null;
    } else if (!timeout && options.trailing !== false) {
      timeout = setTimeout(later, remaining);
    }
    return result;
  };
};
