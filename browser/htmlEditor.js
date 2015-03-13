var plastiq = require('plastiq');
var h = require('plastiq').html;
var Medium = require('medium-editor');

module.exports = function (options) {
  var binding = plastiq.binding(options.binding);

  return h.component(
    {
      onadd: function (element) {
        this.html = binding.get();
        element.innerHTML = normaliseHtml(this.html);

        var editor = new Medium(element);

        element.addEventListener('input', function (ev) {
          binding.set(ev.target.innerHTML);
        });
      },
      onupdate: function () {
        var html = binding.get();

        if (this.html != html) {
          this.html = html;
          element.innerHTML = normaliseHtml(html);
        }
      }
    },
    h('div', {class: options.class})
  );
};

function normaliseHtml(html) {
  if (html) {
    return html;
  } else {
    return '<p><br></p>';
  }
}
