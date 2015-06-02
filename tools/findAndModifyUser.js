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

module.exports = function(api, query, modify, options) {
  var id = options && options.id;
  var env = options && options.env;

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
};
