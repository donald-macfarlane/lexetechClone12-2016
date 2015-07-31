module.exports = function(item, array) {
  var i = array.indexOf(item);
  if (i >= 0) {
    return array.splice(i, 1);
  }
};
