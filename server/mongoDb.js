var mongoose = require("mongoose");

mongoose.set("debug", process.env.MONGO_DEBUG === "true");

var connected = false;

module.exports.connect = function() {
  if (!connected) {
    var url = process.env.MONGOLAB_URI || "mongodb://localhost/lexeme";
    mongoose.connect(url);
    connected = true;
  }
};
