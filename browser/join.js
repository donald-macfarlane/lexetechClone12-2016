module.exports = function(array, dom) {
  var result = [];

  for(var n = 0; n < array.length; n++) {
    if (n !== 0) {
      result.push(dom);
    }
    result.push(array[n]);
  }

  return result;
};
