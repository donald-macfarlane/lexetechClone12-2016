if (window.$) {
  module.exports = window.$;
} else {
  module.exports = require('jquery');
}
