var gulp = require('gulp');
var gutil = require('gulp-util');
var source = require('vinyl-source-stream');
var watchify = require('watchify');
var browserify = require('browserify');
require('pogo');
var watch = require('gulp-watch');
var less = require('gulp-less');
var sourcemaps = require('gulp-sourcemaps');
var shell = require('./tools/ps.pogo');

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
      .pipe(gulp.dest('./server/generated'));
  }
}

gulp.task('default', ['server'])

gulp.task('build', ['js', 'css'])

gulp.task('watch-js', function () {
  var bundle = browserifyBundle(true);
  var watch = watchify(bundle);
  watch.on('update', rebundle(watch));
  rebundle(watch)();
});

gulp.task('js', rebundle(browserifyBundle(false)));

gulp.task('watch-css', function () {
  gulp.src('browser/style/app.less')
    .pipe(watch('browser/style/*.less'))
    .pipe(sourcemaps.init())
    .pipe(less({lineNumbers: 'all'}))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('server/generated'));
});

gulp.task('css', function () {
  gulp.src('browser/style/app.less')
    .pipe(less())
    .pipe(gulp.dest('server/generated'));
});

gulp.task('server', ['watch-js', 'watch-css'], function(done) {
  shell('./node_modules/.bin/pogo server/server.pogo').then(done);
});
