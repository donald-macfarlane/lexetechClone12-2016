var plastiq = require('plastiq');
var rootComponent = require('../../browser/rootComponent');

var lastAttachment;
var lastDiv;
var originalHistoryLength;

module.exports = function (options) {
  if (lastDiv) {
    lastAttachment.remove();
    if (lastDiv.parentNode) {
      lastDiv.parentNode.removeChild(lastDiv);
    }
  }

  if (originalHistoryLength === undefined) {
    originalHistoryLength = history.length;
  }

  var root = rootComponent(options);
  lastDiv = document.createElement('div');
  lastDiv.classList.add('test');
  document.body.appendChild(lastDiv);

  if (history.length > originalHistoryLength) {
    history.go(history.length - originalHistoryLength);
  }

  return lastAttachment = plastiq.append(lastDiv, root.render.bind(root));
};
