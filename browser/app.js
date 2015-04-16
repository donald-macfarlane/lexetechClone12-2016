var plastiq = require('plastiq');

var root = require('./rootComponent')(window.lexemeData);
plastiq.append(document.body, root.render.bind(root));
