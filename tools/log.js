var colors = require('colors/safe');

var colorIndex = 0;
var colors = [
  colors.magenta,
  colors.cyan,
  colors.green,
  colors.yellow,
  colors.blue,
  colors.red
];

function selectColor() {
  return colors[colorIndex++ % colors.length];
}

function logger(name) {
  var color = selectColor();
  function log() {
    var args = [color(name)];
    args.push.apply(args, arguments);
    console.log.apply(console, args);
  }

  log.start = function () {
    var startTime = Date.now();

    return function() {
      var args = [color(name)];
      args.push.apply(args, arguments);
      args.push(color((Date.now() - startTime) + 'ms'));
      console.log.apply(console, args);
    };
  };

  return log;
}

module.exports = logger;
