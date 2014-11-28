var gulp = require('gulp');
var gutil = require('gulp-util');
var webserver = require('gulp-webserver');
var source = require('vinyl-source-stream');
var watchify = require('watchify');
var browserify = require('browserify');

var bundler = watchify(browserify('./app/app.pogo', {
  cache: {},
  packageCache: {},
  fullPaths: true,
  extensions: ['.pogo']
}));
bundler.transform('pogoify');
bundler.on('update', rebundle);

function rebundle() {
  return bundler.bundle()
    .on('error', gutil.log.bind(gutil, 'Browserify Error'))
    .pipe(source('app.js'))
    .pipe(gulp.dest('./public'));
}

gulp.task('default', ['watch', 'server'])

gulp.task('watch', rebundle);

gulp.task('server', function() {
  rebundle();
  gulp.src('public')
    .pipe(webserver({
      livereload: true,
      directoryListing: false,
      open: false,
      fallback: 'index.html'
    }));
});