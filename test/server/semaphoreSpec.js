var semaphore = require('../../server/semaphore');
var expect = require('chai').expect;

describe('semaphore', function () {
  it('can process only one job at a time', function () {
    var s = semaphore();
    var log = [];

    function wait(n) {
      return new Promise(function (fulfil) {
        setTimeout(fulfil, n);
      });
    }

    function job(n) {
      return function () {
        log.push('started job 1');
        return wait(10).then(function () {
          log.push('finished job 1');
        });
      };
    }

    Promise.all(s(job(1)), s(job(2)), s(job(3))).then(function () {
      expect(log).to.eql([
        'started job 1',
        'finished job 1',
        'started job 2',
        'finished job 2',
        'started job 3',
        'finished job 3',
      ]);
    });
  });
});
