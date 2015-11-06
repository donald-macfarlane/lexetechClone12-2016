/** @jsx plastiq.html */
import plastiq from "plastiq";
import httpism from "httpism";
import cache from '../common/cache';

class ContentPage {
  constructor(page) {
    httpism.get('/pages/' + page + '.md').then(response => {
      this.content = response.body;
      this.refresh();
    });
  }

  refresh() {}

  render() {
    this.refresh = plastiq.html.refresh;

    if (this.content) {
      return plastiq.html.rawHtml('.static-page', this.content);
    } else {
      return <div class="static-page"></div>
    }
  }
}

var contentCache = cache();

module.exports = function (page) {
  return contentCache.cacheBy(page, function () {
    return new ContentPage(page);
  });
};
