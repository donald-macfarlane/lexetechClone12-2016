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
      },
      location: function () {
        return location(this.history[this.history.length - 1].url);
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
      routes.route('/report/:id', {
        get: function () {
          if (model.documentId) {
            return {
              id: model.documentId
            }
          }
        },
        set: function (params) {
          model.documentId = params.id;
        }
      });
      routes.route('/login', [model, 'login']);
      routes.route('/signup', [model, 'signup']);
      routes.route('/');
    });

    it('can set the model', function () {
      history.push('/report/6');

      routes.sync();
      expect(model.documentId).to.equal('6');
      expect(history.history).to.eql([{url: '/report/6'}]);

      routes.sync();
      expect(history.history).to.eql([{url: '/report/6'}]);

      model.documentId = 7;
      routes.sync();
      expect(history.history).to.eql([
        {url: '/report/6'},
        {url: '/report/7'},
      ]);

      delete model.documentId;
      routes.sync();
      expect(history.history).to.eql([
        {url: '/report/6'},
        {url: '/report/7'},
        {url: '/'}
      ]);

      model.signup = true;
      routes.sync();
      expect(history.history).to.eql([
        {url: '/report/6'},
        {url: '/report/7'},
        {url: '/'},
        {url: '/signup'}
      ]);
    });
  });
});
