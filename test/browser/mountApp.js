var plastiq = require('plastiq');
var router = require('plastiq-router');

var lastAttachment;
var firstLocation;
var started = false;

module.exports = function (component, options) {
  stop({last: false});

  if (!started) {
    firstLocation = location.pathname + location.search;
    var refresh = document.createElement('a');
    refresh.href = firstLocation;
    refresh.innerText = 'refresh';
    document.body.appendChild(refresh);
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
  var last = options && options.hasOwnProperty('last')? options.last: true;

  if (started && !(firstLocation == '/debug.html' && last)) {
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
