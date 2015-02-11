var plastiq = require('plastiq');
var reportComponent = require('./report');

var report = reportComponent(window.lexemeData);

plastiq.attach(document.body, report.render.bind(report));
