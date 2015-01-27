module.exports = function (b) {
  if (b.name) {
    return b.id + ': ' + b.name;
  } else {
    return b.id;
  }
}
