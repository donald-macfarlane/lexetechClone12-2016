var router = require('../browser/router');
var expect = require('chai').expect;

describe('router', function () {
  var routes;
  var history;

  beforeEach(function () {
    history = {
      history: [],
      push: function (url) {
        this.history.push({url: url});
      },
      replace: function (url) {
        this.history[this.history.length - 1] = {url: url};
      },
      state: {
        get: function () {
          return this.history[this.history.length - 1].state;
        },
        set: function (state) {
          this.history[this.history.length - 1].state = state;
        }
      }
    };
    routes = router({history: history});
  });

  function location(url) {
    var index = url.indexOf('?');
    if (index >= 0) {
      var split = url.split('?');

      return {pathname: url.substring(0, index), search: url.substring(index, url.length)};
    } else {
      return {pathname: url, search: ''};
    }
  }

  context('with normal routes', function () {
    var model;

    beforeEach(function () {
      model = {};
      routes.route('/report/:id', {id: [model, 'documentId']});
      routes.route('/login', [model, 'login']);
      routes.route('/signup', [model, 'signup']);
      routes.route('/');
    });

    it.only('can set the model', function () {
      routes.location(location('/report/6'));
      expect(model.documentId).to.equal('6');
      expect(history.history).to.eql([]);

      routes.location(location('/report/6'));
      expect(history.history).to.eql([]);

      model.documentId = 7;
      routes.location(location('/report/6'));
      expect(history.history).to.eql([{url: '/report/7'}]);

      delete model.documentId;
      routes.location(location('/report/7'));
      expect(history.history).to.eql([
        {url: '/report/7'},
        {url: '/'}
      ]);

      model.signup = true;
      routes.location(location('/'));
      expect(history.history).to.eql([
        {url: '/report/7'},
        {url: '/'},
        {url: '/signup'}
      ]);
    });

    it('can set the location', function () {
      var model = {};

      routes.route('/report/:id', {id: [model, 'documentId']});
      routes.route('/login', [model, 'login']);
      routes.route('/signup', [model, 'signup']);
      routes.route('/');

      expect(routes.location()).to.equal('/');

      model.login = true;
      expect(routes.location()).to.equal('/login');

      model.login = false;
      model.signup = true;
      expect(routes.location()).to.equal('/signup');

      model.signup = false;
      model.documentId = 6;
      expect(routes.location()).to.equal('/report/6');
    });
  });
});
