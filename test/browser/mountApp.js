var plastiq = require('plastiq');

var lastAttachment;
var lastDiv;
var originalHistoryLength;

module.exports = function (component) {
  if (lastDiv) {
    lastAttachment.remove();
    if (lastDiv.parentNode) {
      lastDiv.parentNode.removeChild(lastDiv);
    }
  }

  if (originalHistoryLength === undefined) {
    originalHistoryLength = history.length;
  }

  lastDiv = document.createElement('div');
  lastDiv.classList.add('test');
  document.body.appendChild(lastDiv);

  if (history.length > originalHistoryLength) {
    history.go(history.length - originalHistoryLength);
  }

  return lastAttachment = plastiq.append(lastDiv, component.render.bind(component));
};
