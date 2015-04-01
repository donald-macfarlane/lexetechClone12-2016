var mongoose = require("mongoose");

var Schema = mongoose.Schema;
var Document = new Schema({}, {strict: false});

module.exports = mongoose.model("Document", Document);
