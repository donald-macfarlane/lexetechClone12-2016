var fs = require('fs-promise');
var less = require('less');
var pathUtils = require('path');
var chokidar = require('chokidar');
var colors = require('colors/safe');
var log = require('./log')('less');
var debugVerbose = require('debug')('less:verbose');
var _ = require('underscore');

function compileLess(filename, outputDir, options) {
  var compileLog = log.start();

  return fs.readFile(filename, 'utf-8').then(function (lessContent) {
    var lessOptions = _.clone(options);
    lessOptions.filename = filename;

    return less.render(lessContent, lessOptions).then(function (output) {
      var basename = pathUtils.basename(filename, '.less');
      var cssFilename = pathUtils.join(outputDir, basename + '.css');

      var files = [filename].concat(output.imports);

      if (options && options.sourceMap && !options.sourceMap.sourceMapFileInline) {
        var mapFilename = pathUtils.join(outputDir, basename + '.css.map');
        return Promise.all([
          fs.writeFile(cssFilename, output.css + '/*# sourceMappingURL=' + basename + '.css.map */'),
          fs.writeFile(mapFilename, output.map)
        ]).then(function () {
          compileLog(filename + ' => ' + cssFilename + '[.map]');
          return {
            files: files,
            css: cssFilename,
            map: mapFilename
          };
        });
      } else {
        return fs.writeFile(cssFilename, output.css).then(function () {
          compileLog(filename + ' => ' + cssFilename);
          return {
            files: files,
            css: cssFilename
          };
        });
      }
    });
  });
}

function set(array) {
  var s = {};

  array.forEach(function (key) {
    s[key] = true;
  });

  return s;
}

function comparePaths(a, b) {
  var objectA = set(a);
  var objectB = set(b);

  var added = [];
  var removed = [];

  a.forEach(function (path) {
    if (!objectB[path]) {
      removed.push(path);
    }
  });

  b.forEach(function (path) {
    if (!objectA[path]) {
      added.push(path);
    }
  });

  return {
    added: added,
    removed: removed
  };
}

function watchLess(path, outputDir, options) {
  var paths = [path];
  debugVerbose('watching', paths);
  var watch = chokidar.watch(paths);

  function compile() {
    debugVerbose('compiling', path);
    compileLess(path, outputDir, options).then(function (output) {
      debugVerbose('compiled', path);
      var comparison = comparePaths(paths, output.files);

      if (comparison.added.length) {
        debugVerbose('watching', comparison.added);
        watch.add(comparison.added);
      }
      if (comparison.removed.length) {
        debugVerbose('unwatching', comparison.removed);
        watch.unwatch(comparison.removed);
      }

      paths = output.files;
    }).then(undefined, function (error) {
      console.error(colors.red(error.filename + '(' + error.line + '):' + error.message));
    });
  }

  watch.on('change', function (path) {
    debugVerbose('file changed', path);
    compile();
  });

  compile();
}

exports.compile = compileLess;
exports.watch = watchLess;
