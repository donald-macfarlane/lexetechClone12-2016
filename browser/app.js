window._debug = require('debug');
var plastiq = require('plastiq');
var router = require('plastiq-router');

if (!history.pushState) {
  if (location.pathname == '/') {
    router.start({history: router.hash});
  } else {
    var path = (location.pathname + location.search).replace(/^\//, '');
    location.href = '/#' + path;
  }
} else {
  router.start();
}

var root = require('./rootComponent')(window.lexemeData);
plastiq.append(document.body, root.render.bind(root));
