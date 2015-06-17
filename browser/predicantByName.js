module.exports = function (predicants, id) {
  if (/^user:/.test(id)) {
    return {id: id, name: id};
  } else {
    return predicants[id];
  }
};
