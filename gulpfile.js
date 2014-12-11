var gulp = require('gulp');
var gutil = require('gulp-util');
var webserver = require('gulp-webserver');
var source = require('vinyl-source-stream');
var watchify = require('watchify');
var browserify = require('browserify');
require('pogo');
var run = require('gulp-run');
var watch = require('gulp-watch');
var less = require('gulp-less');
var sourcemaps = require('gulp-sourcemaps');

function browserifyBundle(watch) {
  return browserify('./browser/app.pogo', {
    cache: watch && {},
    packageCache: watch && {},
    fullPaths: watch,
    extensions: ['.pogo'],
    transform: ['pogoify']
  });
}

function rebundle(bundle) {
  return function () {
    console.log("bundling...");
    return bundle.bundle()
      .on('error', gutil.log.bind(gutil, 'Browserify Error'))
      .pipe(source('app.js'))
      .pipe(gulp.dest('./server/public'));
  }
}

gulp.task('default', ['watch', 'server'])

gulp.task('watch', function () {
  var bundle = browserifyBundle(true);
  var watch = watchify(bundle);
  watch.on('update', rebundle(watch));
  rebundle(watch)();
});

gulp.task('bundle', rebundle(browserifyBundle(false)));

gulp.task('less', function () {
  gulp.src('browser/style/app.less')
    .pipe(watch('browser/style/*.less'))
    .pipe(sourcemaps.init())
    .pipe(less({lineNumbers: 'all'}))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('server/public'));
});

gulp.task('server', ['watch', 'less'], function() {
  var port = process.env.PORT || 8000;
  require('./server/server').listen(port);
  console.log("Listening on http://localhost:" + port);
});
