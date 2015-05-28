var plastiq = require('plastiq');
var router = require('plastiq-router');

var lastAttachment;
var lastDiv;
var firstLocation;
var started = false;

module.exports = function (component, options) {
  stop();

  if (!started) {
    firstLocation = location.pathname + location.search;
  }

  started = true;

  lastDiv = appendTestDiv();

  router.start();
  if (options && options.href) {
    history.pushState(undefined, undefined, options.href);
  }
  return lastAttachment = plastiq.append(lastDiv, component.render.bind(component), undefined, {requestRender: setTimeout});
};

function appendTestDiv() {
  var div = document.createElement('div');
  div.classList.add('test');
  document.body.appendChild(div);
  return div;
}

function stop(options) {
  if (started) {
    lastAttachment.remove();

    if (lastDiv.parentNode) {
      lastDiv.parentNode.removeChild(lastDiv);
    }

    if (!(options && options.href)) {
      history.pushState(undefined, undefined, firstLocation);
    }
    router.stop();
  }
}

module.exports.stop = stop;
