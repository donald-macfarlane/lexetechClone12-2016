var React = require('react');
var r = React.createElement;

module.exports = React.createClass({
  componentDidMount: function() {
    var self = this;
    var element = this.getDOMNode();

    if (this.props.inline) {
      this.editor = CKEDITOR.inline(element, this.props.config);
    } else {
      this.editor = CKEDITOR.replace(element, this.props.config);
    }

    this.editor.on('instanceReady', function () {
      self.ready = true;
    });

    this.editor.on('change', function (e) {
      if (!self.settingData) {
        self.html = e.editor.getData();
        if (self.props.onChange) {
          self.props.onChange(self.html);
        }
      }
    });

    this.setHtml(this.props.value);
  },

  setHtml: function (html) {
    var self = this;
    if (html != this.html) {
      this.settingData = true;
      this.html = html;
      this.editor.setData(html, function() {
        self.settingData = false;
      });
    }
  },

  componentWillReceiveProps: function (newprops) {
    this.setHtml(newprops.value);
  },

  componentWillUnmount: function () {
    if (this.ready) {
      this.editor.destroy();
    }
  },

  render: function () {
    if (this.props.inline) {
      return r('div', {className: this.props.className, key: this.props.key, contentEditable: true});
    } else {
      return r('textarea', {className: this.props.className, key: this.props.key});
    }
  }
});
