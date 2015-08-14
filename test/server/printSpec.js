var app = require('../../server/app');
var fs = require('fs');
var httpism = require('httpism');
var expect = require('chai').expect;
var urlUtils = require('url');
var ToughCookie = require('tough-cookie');
var users = require('../../server/users');
var Document = require('../../server/models/document');
var cheerio = require('cheerio');

describe('print', function () {
  var server;
  var browser = httpism.api("http://localhost:12345", {cookies: new ToughCookie.CookieJar()})

  beforeEach(function () {
    server = app.listen(12345);
    return users.deleteAll().then(function () {
      return Document.remove({});
    });
  });

  afterEach(function () {
    server.close();
  });

  it('returns document to be printed', function () {
    var document = {
      lexemes: [
        {
          query: {
            id: '1'
          },
          response: {
            id: '1',
            styles: {
              style1: 'changed',
              style2: 'not changed'
            }
          }
        }
      ]
    };

    return browser.post('/signup', {email: 'bob@example.com', password: 'password'}).then(function (response) {
      return browser.post('/api/user/documents', document).then(function (response) {
        return browser.get('http://localhost:12345/reports/' + response.body.id + '/print/style1').then(function (response) {
          var $ = cheerio.load(response.body);
          var sections = $('.document-outer .document .section').toArray().map(function (section) {
            return $(section).text();
          });

          expect(sections).to.eql(['changed']);
        });
      });
    });
  });
});
