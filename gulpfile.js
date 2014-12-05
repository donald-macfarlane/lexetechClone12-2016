var gulp = require('gulp');
var gutil = require('gulp-util');
var webserver = require('gulp-webserver');
var source = require('vinyl-source-stream');
var watchify = require('watchify');
var browserify = require('browserify');

var browserifyBundle = browserify('./browser/app.pogo', {
  cache: {},
  packageCache: {},
  fullPaths: false,
  extensions: ['.pogo'],
  transform: ['pogoify']
});

function rebundle(bundle) {
  return function () {
    return bundle.bundle()
      .on('error', gutil.log.bind(gutil, 'Browserify Error'))
      .pipe(source('app.js'))
      .pipe(gulp.dest('./public'));
  }
}

gulp.task('default', ['watch', 'server'])

gulp.task('watch', function () {
  var watchifyBundle = watchify(browserifyBundle);
  watchifyBundle.on('update', rebundle(watchifyBundle));

  rebundle(watchifyBundle);
});

gulp.task('bundle', rebundle(browserifyBundle));

gulp.task('server', ['bundle'], function() {
  require('./server/app').listen(8000);
});
