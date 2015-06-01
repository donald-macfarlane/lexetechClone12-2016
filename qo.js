var httpism = require('httpism');
var shell = require('./tools/ps');

var environments = {
  prod: 'http://api:squidandeels@lexetech.herokuapp.com/api/',
  dev: 'http://api:squidandeels@localhost:8000/api/'
};

function mocha() { return shell('mocha test/*Spec.* test/server/*Spec.*'); }
function karma() { return shell('karma start --single-run'); }
function cucumber() { return shell('cucumber'); }

task('mocha', mocha);
task('karma', karma);
task('cucumber', cucumber);

function runAllThenThrow() {
  var tasks = arguments;
  var error;

  function runThen(index) {
    console.log('running', index);
    if (tasks.length > index) {
      tasks[index]().then(function () {
        console.log('finished', index);
        return runThen(index + 1);
      }, function (e) {
        console.log('failed', index);
        if (!error) {
          error = e;
        }
        return runThen(index + 1);
      });
    } else if (error) {
      return Promise.reject(error);
    } else {
      return Promise.resolve();
    }
  }

  return runThen(0);
}

task('test', function () {
  return runAllThenThrow(mocha, karma, cucumber);
});

function createApi(environment) {
  var url = environments[environment || 'dev'];
  return httpism.api(url);
}

function modifyUser(api, href, modify) {
  return api.get(href).then(function (response) {
    var user = response.body;
    modify(user);
    return api.put(user.href, user);
  });
}

function findUsers(api, query) {
  return api.get('users/search', {querystring: {q: query}}).then(function (response) {
    return response.body;
  });
}

function findAndModifyUser(query, modify, options) {
  var id = options && options.id;
  var env = options && options.env;

  var api = createApi(env);

  if (id) {
    return modifyUser(api, 'users/' + id, modify);
  } else {
    return findUsers(api, query).then(function (users) {
      if (users.length === 1) {
        var user = users[0];
        return modifyUser(api, user.href, modify).then(function (response) {
          console.log(response.statusCode + ' => ' + JSON.stringify(response.body, null, 2));
        });
      } else if (users.length > 1) {
        console.log('found more than one user');
        users.forEach(function (user) {
          console.log(JSON.stringify(user, null, 2));
        });
      } else {
        console.log('no users found');
      }
    });
  }
}

task('add-author <user-query> [--env <dev|prod>] [--id <user-id>]', function (args, options) {
  return findAndModifyUser(args[0], function (user) {
    user.author = true;
  }, options);
});

task('add-admin <user-query> [--env <dev|prod>] [--id <user-id>]', function (args, options) {
  return findAndModifyUser(args[0], function (user) {
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
