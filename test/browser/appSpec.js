var prototype = function(p) {
    function constructor() {}
    p = p || {};
    constructor.prototype = p;
    function derive(derived) {
        var o = new constructor();
        if (derived) {
            var keys = Object.keys(derived);
            for (var n = 0; n < keys.length; n++) {
                var key = keys[n];
                o[key] = derived[key];
            }
        }
        return o;
    }
    derive.prototype = p;
    constructor.prototype.constructor = derive;
    return derive;
};
var prototypeExtending = function(p, obj) {
    return prototype(prototype(p.prototype)(obj));
};

var Promise = require("bluebird");
var retry = require("trytryagain");
var lexeme = require("../../browser/lexeme");
var createTestDiv = require("./createTestDiv");
var $ = require("../../browser/jquery");
var expect = require("chai").expect;
var plastiq = require("plastiq");
var rootComponent = require("../../browser/rootComponent");
var queryApi = require("./queryApi");
var lexiconBuilder = require("../lexiconBuilder");
var element = require("./element");
var router = require("plastiq-router");
var _ = require("underscore");
var simpleLexicon = require("../simpleLexicon");
var omitSkipLexicon = require("../omitSkipLexicon");
var repeatingLexicon = require("../repeatingLexicon");

describe("report", function() {
  var div, api, originalLocation, lexicon, reportBrowser, rootBrowser;

  var createRootBrowser = prototypeExtending(element, {
    startNewDocumentButton: function() {
      return this.find(".button", {text: "Start new document"});
    },
    loadCurrentDocumentButton: function() {
      return this.find(".button", {text: "Load current document"});
    },
    loadPreviousButton: function() {
      return this.find(".button", {text: "Load previous document"});
    }
  });

  var createReportBrowser = prototypeExtending(element, {
    undoButton: function() {
      return this.find(".query button", {text: "undo"});
    },

    acceptButton: function() {
      return this.find(".query button", {text: "accept"});
    },

    debugTab: function() {
      return this.find(".tabular .debug");
    },

    normalTab: function() {
      return this.find(".tabular .style-normal");
    },

    debug: function() {
      return debugBrowser(this.find(".debug"));
    },

    document: function() {
      return documentBrowser(this.find(".document"));
    },

    query: function() {
      return queryElement(this.find(".query"));
    },

    responseEditor: function() {
      return responseEditorElement(this.find(".response-editor"));
    }
  });

  var debugBrowser = prototypeExtending(element, {
    block: function(name) {
      return this.find("li").containing("h3", {text: name});
    },

    blockQuery: function(block, query) {
      return this.block(block).find(".block-query", {text: query});
    }
  });

  var documentBrowser = prototypeExtending(element, {
    section: function(text) {
      return this.find(".section", {text: text});
    }
  });

  var queryElement = prototypeExtending(element, {
    response: function(text) {
      return responseElement(this.find(".response", {text: text}));
    },
    skipButton: function() {
      return this.find("button.skip");
    },
    omitButton: function() {
      return this.find("button.omit");
    },
    queryText: function() {
      return this.find(".query-text");
    }
  });

  var responseElement = prototypeExtending(element, {
    link: function() {
      return this.find("a");
    },
    editButton: function() {
      return this.find("button", {text: "edit"});
    }
  });

  var responseEditorElement = prototypeExtending(element, {
    responseTextEditor: function(style) {
      return this.find(".tab.style-" + style + " .response-text-editor");
    },
    okButton: function() {
      return this.find("button", {text: "ok"});
    },
    cancelButton: function() {
      return this.find("button", {text: "cancel"});
    }
  });

  beforeEach(function() {
    div = createTestDiv();
    api = queryApi();
    lexicon = lexiconBuilder();
    originalLocation = location.pathname + location.search + location.hash;
    history.pushState(void 0, void 0, "/");
    rootBrowser = createRootBrowser({element: div});
    reportBrowser = createReportBrowser({element: div});
  });

  afterEach(function() {
    history.pushState(void 0, void 0, originalLocation);
  });

  after(function() {
    router.stop();
  });

  function shouldHaveQuery(query) {
    return reportBrowser.query().queryText().expect(element.hasText(query));
  }

  function shouldBeFinished() {
    return retry(function() {
      return reportBrowser.find(".finished").exists();
    });
  }

  function selectResponse(response) {
    return reportBrowser.find(".query .response:contains(" + JSON.stringify(response) + ") a").click();
  }

  function notesShouldBe(notes) {
    return retry(function() {
      return expect($(".document").text()).to.eql(notes);
    });
  }

  function waitForLexemesToSave(lexemeCount) {
    return retry(function() {
      expect(api.documents.length).to.eql(1);
      expect(api.documents[0].lexemes.length).to.eql(lexemeCount);
    });
  }

  function appendRootComponent(options) {
      options = _.extend({
          user: {
              email: "blah@example.com"
          },
          graphHack: false
      }, options);

      var root = rootComponent(options);
      plastiq.append(div, root.render.bind(root));
  }

  context("with simple lexicon", function() {
    beforeEach(function() {
      api.setLexicon(simpleLexicon());
      appendRootComponent();
      return rootBrowser.startNewDocumentButton().click();
    });

    it("can generate notes by answering queries", function() {
      return shouldHaveQuery("Where does it hurt?").then(function() {
        return selectResponse("left leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldHaveQuery("Is it aching?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldBeFinished();
      }).then(function() {
        return notesShouldBe("Complaint\n---------\nleft leg bleeding, aching");
      });
    });

    describe("documents", function() {
      it("as each query is answered, history is stored in the user's document", function() {
        function simplifyDocuments(docs) {
          return docs.map(function(doc) {
            return doc.lexemes.map(function(lexeme) {
              return {
                query: lexeme.query.id,
                response: lexeme.response.id
              };
            });
          });
        }

        return shouldHaveQuery("Where does it hurt?").then(function() {
          return selectResponse("left leg");
        }).then(function() {
          return retry(function() {
            return expect(simplifyDocuments(api.documents)).to.eql([ [ {
              query: "1",
              response: "1"
            } ] ]);
          });
        }).then(function() {
          return shouldHaveQuery("Is it bleeding?");
        }).then(function() {
          return selectResponse("yes");
        }).then(function() {
          return retry(function() {
            return expect(simplifyDocuments(api.documents)).to.eql([ [ {
              query: "1",
              response: "1"
            }, {
              query: "2",
              response: "1"
            } ] ]);
          });
        }).then(function() {
          return shouldHaveQuery("Is it aching?");
        }).then(function() {
          return selectResponse("yes");
        }).then(function() {
          return shouldBeFinished();
        }).then(function() {
          return retry(function() {
            return expect(simplifyDocuments(api.documents)).to.eql([ [ {
              query: "1",
              response: "1"
            }, {
              query: "2",
              response: "1"
            }, {
              query: "3",
              response: "1"
            } ] ]);
          });
        }).then(function() {
          return notesShouldBe("Complaint\n---------\nleft leg bleeding, aching");
        });
      });
    });

    it("can undo a response, choose a different response", function() {
      return shouldHaveQuery("Where does it hurt?").then(function() {
        return selectResponse("left leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return reportBrowser.find("button", {text: "undo"}).click();
      }).then(function() {
        return shouldHaveQuery("Where does it hurt?");
      }).then(function() {
        return selectResponse("right leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldHaveQuery("Is it aching?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldBeFinished();
      }).then(function() {
        return notesShouldBe("Complaint\n---------\nright leg bleeding, aching");
      }).then(function() {
        return waitForLexemesToSave(3);
      });
    });

    it("can undo a response, and apply it again", function() {
      return shouldHaveQuery("Where does it hurt?").then(function() {
        return selectResponse("left leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return reportBrowser.find("button", {
          text: "undo"
        }).click();
      }).then(function() {
        return shouldHaveQuery("Where does it hurt?");
      }).then(function() {
        return reportBrowser.query().response("left leg").expect(element.is(".selected"));
      }).then(function() {
        return reportBrowser.acceptButton().click();
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldHaveQuery("Is it aching?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldBeFinished();
      }).then(function() {
        return notesShouldBe("Complaint\n---------\nleft leg bleeding, aching");
      }).then(function() {
        return waitForLexemesToSave(3);
      });
    });

    it("can choose another response for a previous query by clicking in the document", function() {
      return shouldHaveQuery("Where does it hurt?").then(function() {
        return selectResponse("left leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldHaveQuery("Is it aching?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return reportBrowser.document().section("bleeding").click();
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return reportBrowser.query().response("yes").expect(element.is(".selected"));
      }).then(function() {
        return reportBrowser.acceptButton().click();
      }).then(function() {
        return shouldHaveQuery("Is it aching?");
      }).then(function() {
        return reportBrowser.query().response("yes").expect(element.is(".selected"));
      }).then(function() {
        return reportBrowser.acceptButton().click();
      }).then(function() {
        return shouldBeFinished();
      }).then(function() {
        return notesShouldBe("Complaint\n---------\nleft leg bleeding, aching");
      }).then(function() {
        return waitForLexemesToSave(3);
      });
    });

    it("can edit the response before accepting it", function() {
      return shouldHaveQuery("Where does it hurt?").then(function() {
        return selectResponse("left leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        var response = reportBrowser.query().response("yes");

        return response.editButton().click().then(function() {
          var editor = reportBrowser.responseEditor();

          return editor.responseTextEditor("style1").typeInHtml("bleeding badly").then(function() {
            return editor.okButton().click();
          }).then(function(gen77_asyncResult) {
            gen77_asyncResult;
            return shouldHaveQuery("Is it aching?");
          }).then(function(gen78_asyncResult) {
            gen78_asyncResult;
            return selectResponse("yes");
          }).then(function(gen79_asyncResult) {
            gen79_asyncResult;
            return shouldBeFinished();
          }).then(function(gen80_asyncResult) {
            gen80_asyncResult;
            return notesShouldBe("Complaint\n---------\nleft leg bleeding badly, aching");
          }).then(function(gen81_asyncResult) {
            gen81_asyncResult;
            return waitForLexemesToSave(3);
          });
        });
      });
    });
  });

  context("lexicon with several blocks", function() {
    beforeEach(function() {
      api.setLexicon(lexicon.blocks([
        {
          id: "1",
          name: "block 1",
          queries: [
            {
              name: "query1",
              text: "Where does it hurt?",
              responses: [
                {
                  text: "left leg",
                  predicants: [ "end" ],
                  actions: [
                    {
                      name: "setBlocks",
                      arguments: [ "1", "2", "3" ]
                    }
                  ],
                  styles: {
                    style1: "Complaint\n---------\nleft leg "
                  }
                }
              ]
            },
            {
              name: "query2",
              text: "Is it bleeding?",
              responses: [
                {
                  text: "yes",
                  styles: {
                    style1: "bleeding"
                  }
                }
              ]
            }
          ]
        },
        {
          id: "2",
          name: "block 2",
          queries: [
            {
              name: "query3",
              text: "are you dizzy?",
              predicants: ["dizzy"],
              responses: [
                {
                  text: "no"
                }
              ]
            }
          ]
        },
        {
          id: "3",
          name: "block 3",
          queries: [
            {
              name: "query4",
              text: "Is it aching?",
              predicants: [ "end" ],
              responses: [
                {
                  text: "yes",
                  styles: {
                    style1: "aching"
                  }
                },
                {
                  text: "no"
                }
              ]
            }
          ]
        }
      ]));

      api.predicants.push({
        id: "end",
        name: "end"
      });

      var root = rootComponent({
        user: {
          email: "blah@example.com"
        },
        graphHack: false
      });

      plastiq.append(div, root.render.bind(root));
      return rootBrowser.startNewDocumentButton().click();
    });

    it("displays debugging information", function() {
      return reportBrowser.debugTab().click().then(function() {
        return shouldHaveQuery("Where does it hurt?");
      }).then(function() {
        return selectResponse("left leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldHaveQuery("Is it aching?");
      }).then(function() {
        return reportBrowser.debug().blockQuery("Block 1", "query1").expect(element.is(".before"));
      }).then(function() {
        return reportBrowser.debug().blockQuery("Block 1", "query2").expect(element.is(".previous"));
      }).then(function() {
        return reportBrowser.debug().blockQuery("Block 2", "query3").expect(element.is(".skipped"));
      }).then(function() {
        return reportBrowser.debug().blockQuery("Block 3", "query4").expect(element.is(".found"));
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldBeFinished();
      }).then(function() {
        return reportBrowser.normalTab().click();
      }).then(function() {
        return notesShouldBe("Complaint\n---------\nleft leg bleedingaching");
      }).then(function() {
        return waitForLexemesToSave(3);
      });
    });
  });

  context("logged in with simple lexicon", function() {
    beforeEach(function() {
      api.setLexicon(simpleLexicon());
      appendRootComponent();
    });

    it("can create a new document", function() {
      return rootBrowser.loadCurrentDocumentButton().has(".disabled").exists().then(function() {
        return rootBrowser.startNewDocumentButton().click();
      }).then(function() {
        return shouldHaveQuery("Where does it hurt?");
      });
    });

    return it("can create a document, make some responses, and come back to it", function() {
      return retry(function() {
        return expect(api.documents.length).to.eql(0);
      }).then(function() {
        return rootBrowser.startNewDocumentButton().click();
      }).then(function() {
        return shouldHaveQuery("Where does it hurt?");
      }).then(function() {
        return selectResponse("left leg");
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return retry(function() {
          return expect(api.documents.length).to.eql(1);
        });
      }).then(function() {
        window.history.back();
        return rootBrowser.loadCurrentDocumentButton().expect(function(element) {
          return !element.has(".disabled");
        });
      }).then(function() {
        return rootBrowser.loadCurrentDocumentButton().click();
      }).then(function() {
        return shouldHaveQuery("Is it bleeding?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldHaveQuery("Is it aching?");
      }).then(function() {
        return selectResponse("yes");
      }).then(function() {
        return shouldBeFinished();
      });
    });
  });

  context("logged in with repeating lexicon", function() {
    beforeEach(function() {
      api.setLexicon(repeatingLexicon());
      appendRootComponent();
    });

    return it("can create a document, make some repeating responses, and come back to it", function() {
      return retry(function() {
        return expect(api.documents.length).to.eql(0);
      }).then(function() {
        return rootBrowser.startNewDocumentButton().click();
      }).then(function() {
        return shouldHaveQuery("One");
      }).then(function() {
        return selectResponse("A");
      }).then(function() {
        return shouldHaveQuery("One");
      }).then(function() {
        return selectResponse("C");
      }).then(function() {
        return shouldHaveQuery("One");
      }).then(function() {
        return retry(function() {
          return expect(api.documents.length).to.eql(1);
        });
      }).then(function() {
        window.history.back();
        return rootBrowser.loadCurrentDocumentButton().expect(function(element) {
          return !element.has(".disabled");
        });
      }).then(function() {
        return rootBrowser.loadCurrentDocumentButton().click();
      }).then(function() {
        return shouldHaveQuery("One");
      }).then(function() {
        return reportBrowser.query().response("A").expect(element.is(".other"));
      }).then(function() {
        return reportBrowser.query().response("C").expect(element.is(".other"));
      }).then(function() {
        return selectResponse("No More");
      }).then(function() {
        return shouldBeFinished();
      });
    });
  });

  return context("logged in with lexicon for omit + skip", function() {
    beforeEach(function() {
      api.setLexicon(omitSkipLexicon());
      appendRootComponent();
      return rootBrowser.startNewDocumentButton().click();
    });

    it("can omit", function() {
      return shouldHaveQuery("query 1, level 1").then(function() {
        return selectResponse("response 1");
      }).then(function() {
        return shouldHaveQuery("query 2, level 1");
      }).then(function() {
        return reportBrowser.query().omitButton().click();
      }).then(function() {
        return shouldHaveQuery("query 3, level 2");
      }).then(function() {
        return selectResponse("response 1");
      }).then(function() {
        return shouldHaveQuery("query 5, level 1");
      }).then(function() {
        return selectResponse("response 1");
      }).then(function() {
        return shouldBeFinished();
      });
    });

    return it("can skip", function() {
      return shouldHaveQuery("query 1, level 1").then(function() {
        return selectResponse("response 1");
      }).then(function() {
        return shouldHaveQuery("query 2, level 1");
      }).then(function() {
        return reportBrowser.query().skipButton().click();
      }).then(function() {
        return shouldHaveQuery("query 5, level 1");
      }).then(function() {
        return selectResponse("response 1");
      }).then(function() {
        return shouldBeFinished();
      });
    });
  });
});
