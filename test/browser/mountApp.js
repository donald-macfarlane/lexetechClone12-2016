var plastiq = require('plastiq');
var router = require('plastiq-router');

var lastAttachment;
var firstLocation;
var started = false;

module.exports = function (component, options) {
  stop();

  if (!started) {
    firstLocation = location.pathname + location.search;
  }

  started = true;

  var div = appendTestDiv();

  router.start();
  if (options && options.href) {
    history.pushState(undefined, undefined, options.href);
  }
  return lastAttachment = plastiq.append(div, component.render.bind(component), undefined, {requestRender: setTimeout});
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

    var divs = document.querySelectorAll('body > div.test');
    Array.prototype.forEach.call(divs, function (div) {
      div.parentNode.removeChild(div);
    });

    if (!(options && options.href)) {
      history.pushState(undefined, undefined, firstLocation);
    }
    router.stop();
  }
}

module.exports.stop = stop;
