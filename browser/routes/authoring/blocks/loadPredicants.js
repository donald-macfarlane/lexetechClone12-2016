var http = require('../http');

module.exports = function() {
  return Promise.all([
    http.get("/api/predicants"),
    http.get("/api/users", {showErrors: false}).then(undefined, function (error) {
      // user doesn't have admin access to see users
      // don't show users
      if (error.statusCode != 403) {
        throw error;
      }
    })
  ]).then(function(results) {
    var predicants = results[0].body;
    var users = results[1].body;

    if (users) {
      users.forEach(function (user) {
        var id = 'user:' + user.id;
        var name = user.firstName + ' ' + user.familyName;
        predicants[id] = {
          id: id,
          name: name
        };
      });
    }

    return predicants;
  });
};
