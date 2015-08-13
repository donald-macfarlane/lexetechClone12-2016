var httpism = require('httpism');

var environments = {
  prod: 'https://api:squidandeels@lexenotes.com/api/',
  staging: 'https://api:squidandeels@lexeme-staging.herokuapp.com/api/',
  dev: 'http://api:squidandeels@localhost:8000/api/'
};

module.exports = function(environment) {
  var url = environments[environment || 'dev'];

  if (!url) {
    throw new Error('no such environment, try one of: ' + Object.keys(environments).join(', '));
  }

  return httpism.api(url);
};

module.exports.environments = environments;
