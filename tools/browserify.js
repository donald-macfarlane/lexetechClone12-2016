var fs = require('fs-promise');
var browserify = require('browserify');
var pathUtils = require('path');
var exorcist = require('exorcist');
var log = require('./log')('browserify');
var uglify = require('./uglify');

module.exports = function (filename, outputDir, options) {
  return new Promise(function (fulfil, reject) {
    var b = browserify('./' + filename, options);
    var bundle = b.bundle();

    bundle.on('error', reject);

    var outputFilename = pathUtils.join(outputDir, pathUtils.basename(filename, pathUtils.extname()));
    var mapFilename = pathUtils.join(outputDir, pathUtils.basename(filename, pathUtils.extname()) + '.map');

    var browserifyLog = log.start();
    bundle.pipe(exorcist(mapFilename)).pipe(fs.createWriteStream(outputFilename)).on('finish', function () {
      browserifyLog(filename + ' => ' + outputFilename + '[.map]');
      fulfil({
        js: outputFilename,
        map: mapFilename
      });
    });
  }).then(function (output) {
    return uglify(output.js, {sourceMap: output.map});
  });
};
