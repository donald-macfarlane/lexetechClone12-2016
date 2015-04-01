var mongoose = require("mongoose");
var Document = require('./models/document');

mongoose.set("debug", process.env.MONGO_DEBUG === "true");

var connected = false;

module.exports.connect = function() {
  if (!connected) {
    var url = process.env.MONGOLAB_URI || "mongodb://localhost/lexeme";
    mongoose.connect(url);
    connected = true;
  }
};

function objectify(doc) {
  if (doc) {
    return doc.toObject();
  }
}

module.exports.writeDocument = function (userId, docId, doc) {
  return Document.update({_id: docId, userId: userId}, {$set: doc}, {overwrite: true}).exec();
};

module.exports.createDocument = function (userId, doc) {
  doc.userId = userId;
  return new Document(doc).save().then(objectify);
};

module.exports.readDocument = function (userId, docId) {
  return Document.findOne({_id: docId, userId: userId}).then(objectify);
};

module.exports.currentDocument = function (userId) {
  return Document.findOne({userId: userId}).sort('-lastModified').then(objectify);
};

module.exports.documents = function (userId) {
  return Document.find({userId: userId}).sort('-lastModified').exec().then(function (docs) {
    return docs.map(objectify);
  });
};
