module.exports = function() {
  var tasks = arguments;
  var error;

  function runThen(index) {
    if (tasks.length > index) {
      return tasks[index]().then(function () {
        return runThen(index + 1);
      }, function (e) {
        if (!error) {
          error = e;
        }
        return runThen(index + 1);
      });
    } else if (error) {
      return Promise.reject(error);
    } else {
      return Promise.resolve();
    }
  }

  return runThen(0);
};
