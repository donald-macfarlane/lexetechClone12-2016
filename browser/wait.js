module.exports = function (n) {
  return new Promise(function (result) {
    setTimeout(result, n);
  });
};
