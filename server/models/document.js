var mongoose = require("mongoose");

var Schema = mongoose.Schema;
var Document = new Schema({}, {strict: false, minimize: false});

module.exports = mongoose.model("Document", Document);
