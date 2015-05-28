var debug = require('debug')('lexenotes:server');

module.exports = function (next) {
  return function (req, res) {
    function sendError(error) {
      debug(error);
      res.status(500).send({message: error.message});
    }

    var result;
    try {
      result = next(req, res);
    } catch (error) {
      sendError(error);
    }

    if (result && typeof result.then === 'function') {
      result.then(undefined, sendError);
    }
  };
};
