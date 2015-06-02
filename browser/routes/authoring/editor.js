var React = require('react');
var r = React.createElement;
var Medium = require('medium-editor');

module.exports = React.createClass({
  componentDidMount: function() {
    var self = this;
    var element = this.getDOMNode();

    if (this.props.value) {
      element.innerHTML = this.props.value;
    } else {
      element.innerHTML = '<p><br></p>';
    }

    this.editor = new Medium(element);

    element.addEventListener('input', function (ev) {
      if (self.props.onChange) {
        self.props.onChange(ev);
      }
    });
  },

  componentDidUpdate: function () {
  },

  componentWillUnmount: function () {
    this.editor.destroy();
  },

  render: function () {
    return r('div', { className: 'editor' });
  }
});
