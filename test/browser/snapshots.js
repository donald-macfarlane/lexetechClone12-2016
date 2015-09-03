var hobostyle = require('hobostyle');

function Snapshots() {
  this.createSnapshots();
}

Snapshots.prototype.createSnapshots = function () {
  hobostyle.style(
    '.test-snapshots {}\n' +
    '.test-snapshot-container {\n' +
    '  display: inline-block;\n' +
    '  padding: 10px;\n' +
    '  background-color: white;\n' +
    '  margin: 5px;\n' +
    '}\n' +
    '.test-snapshot {\n' +
    '  background-color: blue;\n' +
    '  transform: scale(0.2);\n' +
    '  transform-origin: top left;\n' +
    '}'
  );

  this.snapshots = document.createElement('div');
  this.snapshots.className = 'test-snapshots';
  document.body.appendChild(this.snapshots);
};

Snapshots.prototype.add = function(testDiv) {
  var snapshot = testDiv.cloneNode(true);
  snapshot.className = 'test-snapshot';
  var snapshotContainer = document.createElement('div');
  snapshotContainer.className = 'test-snapshot-container';

  var $testDiv = $(testDiv);
  var width = Number($testDiv.css('width').replace(/px$/, ''));
  var height = Number($testDiv.css('height').replace(/px$/, ''));

  var $snapshot = $(snapshot);
  $snapshot.css({width: Math.round(width * 0.2 + 20) + 'px'});
  $snapshot.css({height: Math.round(height * 0.2 + 20) + 'px'});

  var $snapshotContainer = $(snapshotContainer);
  $snapshotContainer.css({width: Math.round(width * 0.2 + 20) + 'px'});
  $snapshotContainer.css({height: Math.round(height * 0.2 + 20) + 'px'});

  snapshotContainer.appendChild(snapshot);
  this.snapshots.appendChild(snapshotContainer);
};

module.exports = function () {
  return new Snapshots();
};
