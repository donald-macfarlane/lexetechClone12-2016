var httpism = require('httpism');

var environments = {
  prod: 'http://api:squidandeels@lexetech.herokuapp.com/api/',
  dev: 'http://api:squidandeels@localhost:8000/api/'
};

module.exports = function(environment) {
  var url = environments[environment || 'dev'];
  return httpism.api(url);
};
