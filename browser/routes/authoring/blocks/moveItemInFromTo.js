module.exports = function (item, from, to) {
  list.splice(to, 0, list.splice(from, 1)[0]);
};
