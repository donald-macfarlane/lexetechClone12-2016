var Promise = require("bluebird");
var childProcess = require("child_process");
var shellQuote = require("shell-quote");
var glob = require("glob");

function shell(cmd, args, opts) {
  var p;
  if (!(args instanceof Array)) {
    return shell("sh", [ "-c", cmd ], args);
  } else {
    args = args || [];
    opts = opts || {};

    if (opts.env) {
      opts.env = JSON.parse(JSON.stringify(opts.env));
      Object.keys(process.env).forEach(function(key) {
        return opts.env[key] = process.env[key];
      });
    }

    opts.stdio = opts.stdio || "inherit";

    var p = childProcess.spawn(cmd, args, opts);

    return new Promise(function(result, error) {
      return p.on("exit", function(exitCode) {
        if (exitCode === 0) {
          return result();
        } else {
          return error(new Error(shellQuote.quote([ cmd ].concat(args)) + ", exit code " + exitCode));
        }
      });
    });
  }
}

module.exports = shell;
