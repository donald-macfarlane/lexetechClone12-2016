var gulp = require('gulp');
var gutil = require('gulp-util');
var webserver = require('gulp-webserver');
var source = require('vinyl-source-stream');
var watchify = require('watchify');
var browserify = require('browserify');

gulp.task('default', ['watch', 'server'])

gulp.task('watch', function() {
  var bundler = watchify(browserify('./app/app.pogo', watchify.args));
  bundler.transform('pogoify');
  bundler.on('update', rebundle);

  function rebundle() {
    return bundler.bundle()
      .on('error', gutil.log.bind(gutil, 'Browserify Error'))
      .pipe(source('app.js'))
      .pipe(gulp.dest('./public'));
  }

  return rebundle();
});

gulp.task('server', function() {
  gulp.src('public')
    .pipe(webserver({
      livereload: true,
      directoryListing: false,
      open: false,
      fallback: 'index.html'
    }));
});