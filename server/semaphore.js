module.exports = function () {
  var executing = false;

  function run(block) {
    if (!executing) {
      executing = block();
      return executing.then(function (value) {
        executing = false;
        return value;
      });
    } else {
      executing.then(function () {
        return run(block);
      });
    }
  }

  return run;
}
