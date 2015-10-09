var shell = require('./tools/ps');
var runAllThenThrow = require('./tools/runAllThenThrow');
var createApi = require('./tools/createApi');
var findAndModifyUser = require('./tools/findAndModifyUser');
var fs = require('fs-promise');
var _ = require('underscore');
var promisify = require('./server/promisify');
var Promise = require('bluebird');
var pathUtils = require('path');

var glob = Promise.promisify(require('glob'));

function runIndySpecs() {
  return glob('test/server-indy/*Spec.*').then(function (files) {
    return Promise.each(files, function (file) {
      return shell('mocha', [file]);
    });
  })
}

function mocha() {
  return shell('mocha test/*Spec.* test/server/*Spec.*').then(function () {
    return runIndySpecs();
  });
}
function karma() { return shell('karma start --single-run'); }
function cucumber() { return shell('cucumber'); }

var envArg = '[--env <' + Object.keys(createApi.environments).join('|') + '>]'

task('mocha', mocha);
task('karma', karma);
task('cucumber', cucumber);

task('test', function () {
  return runAllThenThrow(mocha, karma, cucumber);
});

function addAuthor(username, options) {
  return findAndModifyUser(createApi(options.env), username, function (user) {
    user.author = true;
  }, options);
}

function addAdmin(username, options) {
  return findAndModifyUser(createApi(options.env), username, function (user) {
    user.admin = true;
  }, options);
}

task('add-author <user-query> ' + envArg + ' [--id <user-id>]', function (args, options) {
  return addAuthor(args[0], options);
});

task('add-admin <user-query> ' + envArg + ' [--id <user-id>]', function (args, options) {
  return addAdmin(args[0], options);
});

task('undelete <href> ' + envArg, function (args, options) {
  var api = createApi(options.env);

  return api.get(args[0]).then(function (response) {
    delete response.body.deleted;

    return api.put(response.body.href, response.body);
  });
});

task('lexicon ' + envArg, function (args, options) {
  var api = createApi(options.env);
  return api.get('lexicon').then(function (response) {
    console.log(JSON.stringify(response.body, null, 2))
  });
});

task('clear-lexicon ' + envArg, function (args, options) {
  var api = createApi(options.env);
  return api.post('lexicon', {blocks: []}).then(function (response) {
    console.log(JSON.stringify(response.body, null, 2))
  });
});

function putLexeme(file, options) {
  return fs.readFile(file, 'utf-8').then(function (content) {
    var lexicon = JSON.parse(content);
    var api = createApi(options.env);
    return api.post('lexicon', lexicon).then(function (response) {
      console.log(response.statusCode + ' => ' + JSON.stringify(response.body, null, 2));
    });
  });
}

task('put-lexicon ' + envArg + ' <lexicon.json>', function (args, options) {
  return putLexeme(args[0], options);
});

task('clear-documents', function () {
  var Document = require('./server/models/document')
  return promisify(function (cb) {
    Document.remove({}, cb);
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
  },
  local: {
    user: "lexeme",
    password: "password",
    server: "windows",
    database: "dbLexeme"
  }
};

task('sql-lexicon ' + envArg, function (args, options) {
  require('pogo');
  var loadQueriesFromSql = require('./tools/loadQueriesFromSql');

  var creds = sqlCreds[options.env || 'local'];

  return loadQueriesFromSql(creds).then(function (lexicon) {
    console.log(JSON.stringify(lexicon, null, 2));
  });
});

task('styles <lexicon.json>', function (args) {
  var filename = args[0];

  return fs.readFile(filename, 'utf-8').then(function (content) {
    var lexicon = JSON.parse(content);

    var styles = _.flatten(lexicon.blocks.map(function (block) {
      return block.queries.map(function (query) {
        return query.responses.map(function (response) {
          return Object.keys(response.styles).map(function (styleKey) {
            return {block: block.id, query: query.id, response: response.id, style: styleKey, text: response.styles[styleKey]};
          });
        });
      });
    }));

    process.stdout.write('block\tquery\tresponse\tstyle\ttext\n');

    styles.forEach(function (style) {
      process.stdout.write(style.block + '\t' + style.query + '\t' + style.response + '\t' + style.style + '\t' + JSON.stringify(style.text) + '\n');
    });
  });
});

task('merge-styles styles.tab lexicon.json', function (args) {
  var stylesFilename = args[0];
  var lexiconFilename = args[1];

  return Promise.all([
    fs.readFile(stylesFilename, 'utf-8'),
    fs.readFile(lexiconFilename, 'utf-8')
  ]).then(function (results) {
    var lines = results[0].split('\n');
    var lexicon = JSON.parse(results[1]);

    lines.forEach(function (line, index) {
      if (index !== 0 && line) {
        var fields = line.split('\t');

        var block = fields[0];
        var query = fields[1];
        var response = fields[2];
        var style = fields[3];
        var text = fields[4];

        var b = lexicon.blocks.filter(function (b) { return b.id == block; })[0];
        var q = b.queries.filter(function (q) { return q.id == query; })[0];
        
        if (q) {
          var resp = q.responses.filter(function (r) { return r.id == response; })[0];
          resp.styles[style] = JSON.parse(text);
        } else {
          process.stderr.write('could not find query with ID: ' + query + '\n');
        }
      }
    });

    console.log(JSON.stringify(lexicon, null, 2));
  });
});

task('api <href> ' + envArg, {desc: 'show the JSON of an API resource, e.g. blocks/1'}, function (args, options) {
  var path = args[0];

  return createApi(options.env).get(path).then(function (response) {
    console.log(JSON.stringify(response.body, null, 2));
  });
});

function postPut(method, args, options) {
  function postJson(content) {
    var json = JSON.parse(content);
    return createApi(options.env)[method](href || json.href, json).then(function (response) {
      console.log(response.statusCode + ' => ' + JSON.stringify(response.body, null, 2));
    });
  }

  if (options.d) {
    var href = args[0];
    return postJson(options.d);
  } else {
    var path = args[0];
    var href = args[1];
    return fs.readFile(path, 'utf-8').then(postJson);
  }
}

task('api-delete <href>', function (args, options) {
  var path = args[0];

  return createApi(options.env).delete(path).then(function (response) {
    console.log(JSON.stringify(response.body, null, 2));
  });
});

['post', 'put'].forEach(function (method) {
  task('api-' + method + ' [<file.json>|-d <json>] [<href>] ' + envArg, {desc: 'put the JSON representation of an API resource. If the JSON has a `href` it will be used.'}, function (args, options) {
    return postPut(method, args, options);
  });
});

task('semantic-ie9', function () {
  return shell('blessc semantic/dist/semantic.css semantic/dist/semantic.ie.css');
});

task('less-vars definition.less', function (args) {
  var file = args[0];

  return glob('semantic/src/definitions/**/*.less').then(function (paths) {
    for (var n = 0; n < paths.length; n++) {
      var path = paths[n];
      if (pathUtils.basename(path) == file) {
        return shell('less-vars', [path]);
      }
    }

    console.log('no such definition, try one of:');
    console.log();
    var basenames = paths.map(pathUtils.basename);
    basenames.forEach(function (name) {
      console.log('    ' + name);
    });

    console.log();
  });
});

task("remove-none-actions # at one point we had 'none' actions, which weren't that useful so we removed them", function (args) {
  var file = args[0];

  var json = require('./' + file);

  return fs.writeFile(file + '.old', JSON.stringify(json, null, 2)).then(function () {
    json.blocks.forEach(function (block) {
      block.queries.forEach(function (query) {
        query.responses.forEach(function (response) {
          response.actions = response.actions.filter(function (action) {
            return action.name != 'none';
          });
        });
      });
    });

    return fs.writeFile(file + '.new', JSON.stringify(json, null, 2)).then(function () {
      return shell('diff ' + file + '.old ' + file + '.new | less');
    });
  });
});

task('test-data', function () {
  var options = {};

  return addAuthor('author@surgery.com', options).then(function () {
    return addAdmin('author@surgery.com', options);
  }).then(function () {
    return putLexeme('lexicon.json', options);
  });
});
