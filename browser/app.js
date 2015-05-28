window.lexemeDebug = require('debug');
var plastiq = require('plastiq');
var router = require('plastiq-router');

router.start();

var root = require('./rootComponent')(window.lexemeData);
plastiq.append(document.body, root.render.bind(root));
