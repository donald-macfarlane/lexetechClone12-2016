var fs = require('fs-promise');
var handlebars = require('handlebars');

function load(name) {
  return fs.readFile(__dirname + '/emailTemplates/' + name, 'utf-8').then(function (text) {
    return handlebars.compile(text);
  });
}

module.exports.load = load;

module.exports.buildEmail = function (template, email, data) {
  return Promise.all([
    load(template + '.txt'),
    load(template + '.html')
  ]).then(function (templates) {
    email.text = templates[0](data);
    email.html = templates[1](data);
    return email;
  });
};
