var gulp = require('gulp');
var gutil = require('gulp-util');
var source = require('vinyl-source-stream');
var buffer = require('vinyl-buffer');
var watchify = require('watchify');
var browserify = require('browserify');
require('pogo');
var watch = require('gulp-watch');
var less = require('gulp-less');
var sourcemaps = require('gulp-sourcemaps');
var shell = require('./tools/ps.pogo');
var gulpMerge = require('gulp-merge');
var pathUtils = require('path');

function browserifyBundle(watch, filename) {
  return browserify(filename, {
    cache: watch && {},
    packageCache: watch && {},
    fullPaths: watch,
    extensions: ['.pogo'],
    transform: ['pogoify'],
    debug: watch
  });
}

function rebundle() {
  var bundles = Array.prototype.slice.call(arguments, 0);

  return function () {
    console.log("bundling...");
    function basenameNoExt(x) {
      return pathUtils.basename(x, pathUtils.extname(x));
    }

    var bundlesWithErrors = bundles.map(function (b) {
      var bundle = b.bundle();
      bundle.on('error', gutil.log.bind(gutil, 'Browserify Error'));
      return bundle.pipe(source(basenameNoExt(b._options.entries[0]) + '.js'));
    });

    return gulpMerge.apply(undefined, bundlesWithErrors)
      .pipe(gulp.dest('./server/generated'));
  }
}

gulp.task('default', ['server'])

gulp.task('build', ['js', 'css'])

function watchJs(filename) {
  var bundle = browserifyBundle(true, filename);
  var watch = watchify(bundle);
  watch.on('update', rebundle(watch));
  rebundle(watch)();
}

gulp.task('watch-js', function () {
  watchJs('./browser/app.js');
  watchJs('./browser/authoring.pogo');
  watchJs('./browser/debug.js');
});

gulp.task('js',
  rebundle(
    browserifyBundle(false, './browser/app.js'),
    browserifyBundle(false, './browser/authoring.pogo'),
    browserifyBundle(false, './browser/debug.js')
  )
);

gulp.task('watch-css', function () {
  gulp.src('browser/style/app.less')
    .pipe(watch('browser/style/*.less'))
    .pipe(sourcemaps.init())
    .pipe(less({lineNumbers: 'all'}))
    .pipe(sourcemaps.write('.'))
    .on('error', gutil.log.bind(gutil, 'Less Error'))
    .pipe(gulp.dest('server/generated'));
});

gulp.task('css', function () {
  gulp.src('browser/style/app.less')
    .pipe(less())
    .on('error', gutil.log.bind(gutil, 'Less Error'))
    .pipe(gulp.dest('server/generated'));
});

gulp.task('server', ['watch-js', 'watch-css'], function(done) {
  shell('./node_modules/.bin/pogo server/server.pogo').then(done);
});
