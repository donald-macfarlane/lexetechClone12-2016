var gulp = require('gulp');
var gutil = require('gulp-util');
var source = require('vinyl-source-stream');
var streamify = require('gulp-streamify');
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
var uglify = require('gulp-uglify');
var gulpif = require('gulp-if');

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

function rebundle(options) {
  var bundles = Array.prototype.slice.call(arguments, 1);

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
      .pipe(gulpif(options.minify, streamify(uglify())))
      .pipe(gulp.dest('./server/generated'));
  }
}

gulp.task('default', ['server'])

gulp.task('build', ['js', 'css'])

function watchJs(filename) {
  var bundle = browserifyBundle(true, filename);
  var watch = watchify(bundle);
  watch.on('update', rebundle({}, watch));
  rebundle({}, watch)();
}

gulp.task('watch-js', function () {
  watchJs('./browser/app.js');
  watchJs('./browser/authoring.pogo');
});

gulp.task('js',
  rebundle(
    {minify: true},
    browserifyBundle(false, './browser/app.js'),
    browserifyBundle(false, './browser/authoring.pogo')
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

  gulp.src('browser/style/print/report.less')
    .pipe(watch('browser/style/print/report.less'))
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

  gulp.src('browser/style/print/report.less')
    .pipe(less())
    .on('error', gutil.log.bind(gutil, 'Less Error'))
    .pipe(gulp.dest('server/generated'));
});

var mandrill = {
  username: 'app32417512@heroku.com',
  apikey: 'udYXr_wWlBxJDtrKNPTH0w'
}

function runServer(done) {
  var env = {
    DEBUG: 'lexenotes:*',
    MANDRILL_USERNAME: mandrill.username,
    MANDRILL_APIKEY: mandrill.apikey,
    ADMIN_EMAIL: 'Tim Macfarlane <tim+lexenotes-admin@featurist.co.uk>',
    SYSTEM_EMAIL: 'Tim Macfarlane <tim+lexenotes-system@featurist.co.uk>'
  };

  shell('node server/server.js', {env: env}).then(done);
}

gulp.task('server', ['watch-js', 'watch-css'], runServer);
gulp.task('server-no-watch', ['js', 'css'], runServer);
