var shell = require('./tools/ps');
var runAllThenThrow = require('./tools/runAllThenThrow');
var createApi = require('./tools/createApi');
var findAndModifyUser = require('./tools/findAndModifyUser');
var fs = require('fs-promise');

function mocha() { return shell('mocha test/*Spec.* test/server/*Spec.*'); }
function karma() { return shell('karma start --single-run'); }
function cucumber() { return shell('cucumber'); }

task('mocha', mocha);
task('karma', karma);
task('cucumber', cucumber);

task('test', function () {
  return runAllThenThrow(mocha, karma, cucumber);
});

task('add-author <user-query> [--env <dev|prod>] [--id <user-id>]', function (args, options) {
  return findAndModifyUser(createApi(options), args[0], function (user) {
    user.author = true;
  }, options);
});

task('add-admin <user-query> [--env <dev|prod>] [--id <user-id>]', function (args, options) {
  return findAndModifyUser(createApi(options), args[0], function (user) {
    user.admin = true;
  }, options);
});

task('undelete <href> [--env <env>]', function (args, options) {
  var api = createApi(options.env);

  return api.get(args[0]).then(function (response) {
    delete response.body.deleted;

    return api.put(response.body.href, response.body);
  });
});

task('lexicon --env <env=dev>', function (args, options) {
  var api = createApi(options.env);
  return api.get('lexicon').then(function (response) {
    console.log(JSON.stringify(response.body, null, 2))
  });
});

task('put-lexicon --env <env=dev> <lexicon.json>', function (args, options) {
  var file = args[0];
  return fs.readFile(file, 'utf-8').then(function (content) {
    var lexicon = JSON.parse(content);
    var api = createApi(options.env);
    return api.post('lexicon', lexicon).then(function (response) {
      return response.statusCode + ' => ' + JSON.stringify(response.body, null, 2);
    });
  });
});

var sqlCreds = {
  prod: {
    server: "74.208.163.231\\SQLExpress",
    database: "dbLexeme",
    user: "LexemeUser",
    password: "wsi824"
  },
  dev: {
    user: "LexemeUser",
    password: "wsi824",
    server: "74.208.222.170",
    database: "dbLexeme"
  }
};

task('sqldump --env <env=dev>', function (args, options) {
  require('pogo');
  var loadQueriesFromSql = require('./tools/loadQueriesFromSql');

  var creds = sqlCreds[options.env || 'dev'];

  return loadQueriesFromSql(creds).then(function (lexicon) {
    console.log(JSON.stringify(lexicon, null, 2));
  });
});
