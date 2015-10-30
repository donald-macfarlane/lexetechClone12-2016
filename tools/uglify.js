var fs = require('fs-promise');
var UglifyJS = require('uglify-js');
var log = require('./log')('uglify');
var pathUtils = require('path');

module.exports = function (js, options) {
  var sourceMap = typeof options == 'object' && options.hasOwnProperty('sourceMap')? options.sourceMap: undefined;
  var ext = typeof options == 'object' && options.hasOwnProperty('ext')? options.ext: '';

  var minJs = pathUtils.join(pathUtils.dirname(js), pathUtils.basename(js, '.js') + ext + '.js');
  var minJsMap = pathUtils.join(pathUtils.dirname(sourceMap), pathUtils.basename(sourceMap, '.js.map') + ext + '.js.map');

  var uglifyLog = log.start();

  var result = UglifyJS.minify(js, {
    inSourceMap: sourceMap,
    outSourceMap: minJsMap
  });

  return Promise.all([
    fs.writeFile(minJs, result.code),
    fs.writeFile(minJsMap, result.map)
  ]).then(function () {
    uglifyLog(js + ' => ' + minJs + '[.map]');
  });
};
