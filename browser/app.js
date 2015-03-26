var plastiq = require('plastiq');

var root = require('./root')(window.lexemeData);
plastiq.append(document.body, root.render.bind(root));
