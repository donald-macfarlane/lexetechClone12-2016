module.exports = function (existing, entity) {
  Object.keys(existing).forEach(function (k) {
    delete existing[k];
  });

  Object.keys(entity).forEach(function (k) {
    existing[k] = entity[k];
  });
};
