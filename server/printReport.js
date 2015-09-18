var express = require("express");
var app = express();
var routes = require('../browser/routes');
var createHistory = require('../browser/history');
var createDocumentComponent = require('../browser/documentComponent');
var mongoDb = require('./mongoDb');
var vdomToHtml = require('vdom-to-html');

app.set("views", __dirname + "/views");

app.get(routes.printReport.pattern, function (req, res) {
  var documentId = req.params.documentId;
  var style = req.params.style;

  return mongoDb.readDocument(req.user.id, documentId).then(function(doc) {
    var history = createHistory({document: doc, dontUpdateStyles: true});
    var documentComponent = createDocumentComponent({history: history});
    var vdom = documentComponent.render('style1');
    var html = vdomToHtml(vdom);
    res.render("print.html", {document: html});
  });
});

module.exports = app;
