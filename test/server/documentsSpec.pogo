httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect
_ = require 'underscore'
Document = require '../../server/models/document'
startSmtpServer = require './smtpServer'
retry = require 'trytryagain'
lexiconBuilder = require '../lexiconBuilder'
debug = (require 'debug') 'documents-spec'

describe 'documents'
  port = 12345
  api = httpism.api "http://bob:password@localhost:#(port)"
  server = nil

  beforeEach
    app.set 'apiUsers' {
      "bob:password" = {
        email = 'bob@example.com'
        firstName = 'Bob'
        familyName = 'Jacobs'
      }
    }
    server := app.listen (port)
    Document.remove {} ^!

  afterEach
    server.close()

  it 'creates new documents with different URLs'
    response1 = api.post!('/api/user/documents')
    response2 = api.post!('/api/user/documents')

    expect(response1.headers.location).to.not.equal(response2.headers.location)
    expect(response1.body.href).to.equal(response1.headers.location)
    expect(response2.body.href).to.equal(response2.headers.location)

  it 'when creating 6th document, deletes document with oldest last modified date'
    response1 = api.post!('/api/user/documents', {name = '1'})
    response2 = api.post!('/api/user/documents', {name = '2'})
    response3 = api.post!('/api/user/documents', {name = '3'})
    response4 = api.post!('/api/user/documents', {name = '4'})
    response5 = api.post!('/api/user/documents', {name = '5'})

    api.put! (response1.body.href) {
      name = 'update 1'
    }

    api.put! (response2.body.href) {
      name = 'update 2'
    }

    response6 = api.post!('/api/user/documents', {name = '6'})

    api.get! (response1.body.href)
    api.get! (response2.body.href)
    api.get! (response4.body.href)
    api.get! (response5.body.href)
    api.get! (response6.body.href)

    expect(api.get! (response3.body.href, exceptions: false).statusCode).to.equal(404)

  it 'can delete a document'
    doc1 = api.post!('/api/user/documents').body
    doc2 = api.post!('/api/user/documents').body

    expect(api.delete!(doc1.href).statusCode).to.equal(204)

    expect(api.get!(doc1.href, exceptions = false).statusCode).to.equal(404)
    expect(api.get!(doc2.href).body.href).to.equal(doc2.href)

    list = api.get!('/api/user/documents').body
    expect(list).to.eql([doc2])

  it 'adds a created field to documents as they are created, and a lastModified as they are updated'
    document = api.post!('/api/user/documents').body

    now = @new Date().getTime()
    expect(Date.parse(document.lastModified)).to.be.within(now - 1000, now)
    expect(document.created).to.equal(document.lastModified)

    document.query = 'query 1'

    documentUpdate = api.post!(document.href, document).body
    expect(Date.parse(documentUpdate.lastModified)).to.be.greaterThan(Date.parse(document.lastModified))
    expect(Date.parse(documentUpdate.created)).to.be.equal(Date.parse(document.created))

  it 'can list documents'
    response1 = api.post!('/api/user/documents').body
    response2 = api.post!('/api/user/documents').body
    list = api.get!('/api/user/documents').body

    expect(list).to.eql([response2, response1])

  it 'can create a document, and put updates to it'
    response = api.post!('/api/user/documents')
    docUrl = response.headers.location
    doc = response.body
    doc.query = 'blah'
    doc.predicants = {}

    api.post!(docUrl, doc)

    expect(removeDate(api.get!(docUrl).body)).to.eql(removeDate(doc))

  it 'returns no documents when there no documents'
    response = api.get!('/api/user/documents').body
    expect(response).to.eql []

  it 'only the original author can see documents they create'
    user1 = httpism.api "http://user1:password@localhost:#(port)"
    user2 = httpism.api "http://user2:password@localhost:#(port)"
    app.set 'apiUsers' {
      "user1:password" = true
      "user2:password" = true
    }

    response = user1.post!('/api/user/documents', {
      query = "user 1's"
    })
    docUrl = response.headers.location
    doc = response.body

    expect(user2.get!(docUrl, exceptions = false).statusCode).to.equal(404)
    doc.query = "user 2's edit"
    user2.post!(docUrl, doc)

    expect(user1.get!(docUrl).body.query).to.eql("user 1's")

  it 'only the original author can delete documents they create'
    user1 = httpism.api "http://user1:password@localhost:#(port)"
    user2 = httpism.api "http://user2:password@localhost:#(port)"
    app.set 'apiUsers' {
      "user1:password" = true
      "user2:password" = true
    }

    response = user1.post!('/api/user/documents', {
      query = "user 1's"
    })
    docUrl = response.headers.location
    doc = response.body

    expect(user2.delete!(docUrl, exceptions = false).statusCode).to.equal(404)

    expect(user1.get!(docUrl).body.query).to.eql("user 1's")

  removeDate(obj) = _.omit(obj, 'lastModified')

  it 'remember the last document written to'
    expect(api.get!('/api/user/documents/current', exceptions = false).statusCode).to.eql 404

    response1 = api.post!('/api/user/documents', {
      query = 'query 1'
    })

    expect(api.get!('/api/user/documents/current').body.query).to.eql 'query 1'

    response2 = api.post!('/api/user/documents', {
      query = 'query 2'
    })

    expect(api.get!('/api/user/documents/current').body.query).to.eql 'query 2'

    api.post!(response1.headers.location, {
      query = 'query 1, altered'
    })

    expect(api.get!('/api/user/documents/current').body.query).to.eql 'query 1, altered'

    api.post!(response2.headers.location, {
      query = 'query 2, altered'
    })

    expect(api.get!('/api/user/documents/current').body.query).to.eql 'query 2, altered'

  describe 'emailing administrator when changes are made to responses'
    smtpServer = nil

    beforeEach
      smtpServer := startSmtpServer!()
      app.set 'smtp url' (smtpServer.url)
      db = app.get 'db'
      lexicon = lexiconBuilder()
      db.setLexicon(lexicon.queries [
        {
          id = 1

          responses [
            {
              id = 1

              styles = {
                style1 'not changed'
                style2 'not changed'
              }
            }
          ]
        }
        {
          id = 2

          responses [
            {
              id = 1

              styles = {
                style1 'not changed'
                style2 'not changed'
              }
            }
          ]
        }
      ])!

    afterEach
      smtpServer.stop()

    describe 'spotting differences'
      beforeEach
        db = app.get 'db'
        lexicon = lexiconBuilder()
        db.setLexicon(lexicon.queries [
          {
            id = 1

            responses [
              {
                id = 1

                styles = {
                  style1 'not changed'
                  style2 'not changed'
                }
              }
            ]
          }
          {
            id = 2

            responses [
              {
                id = 1

                styles = {
                  style1 'not changed'
                  style2 'not changed'
                }
              }
            ]
          }
        ])!

      lexemeWithChangedStyles(queryId = 1, responseId = 1) = {
        query = {
          id = queryId
        }
        response = {
          id = responseId
          styles {
            style1 = 'changed'
            style2 = 'not changed'
          }
          changedStyles = {
            style1 = true
            style2 = false
          }
        }
      }

      lexemeWithOriginalStyles(queryId = 1, responseId = 1) = {
        query = {
          id = queryId
        }
        response = {
          id = responseId
          styles {
            style1 = 'not changed'
            style2 = 'not changed'
          }
          changedStyles = {
            style1 = false
            style2 = false
          }
        }
      }
        
      describe 'when creating the document'
        it 'emails the administrator when a change is made to a response when first creating the document'
          api.post!('/api/user/documents', {
            lexemes = [
              lexemeWithChangedStyles()
            ]
          })

          retry!
            expect(smtpServer.emails.length).to.equal 1
          
        it "doesn't email the administrator when no changes are made to the responses"
          api.post!('/api/user/documents', {
            lexemes = [
              lexemeWithOriginalStyles()
            ]
          })

          retry.ensuring!
            expect(smtpServer.emails.length).to.equal 0

      describe 'when updating a document with changed styles'
        document = nil

        beforeEach
          document := api.post!('/api/user/documents', {
            lexemes = [
              lexemeWithChangedStyles()
            ]
          }).body

          retry!
            expect(smtpServer.emails.length).to.equal 1

          smtpServer.clear()
            
        it 'sends an email when the update contains a changed style'
          document.lexemes.push(lexemeWithChangedStyles(queryId = 2, responseId = 1))
          api.put!(document.href, document)

          retry!
            expect(smtpServer.emails.length).to.equal 1
          
        it "doesn't send an email when the update doesn't contain a changed style"
          document.lexemes.push(lexemeWithOriginalStyles(queryId = 2, responseId = 1))
          api.put!(document.href, document)

          retry.ensuring!
            expect(smtpServer.emails.length).to.equal 0

    describe 'showing differences'
      fs = require 'fs-promise'

      beforeEach
        try
          fs.unlink 'email.html'!
        catch (e)
          nil

        db = app.get 'db'
        lexicon = lexiconBuilder()
        db.setLexicon(lexicon.queries [
          {
            id = 1
            name = 'query:1'
            text = 'query 1'

            responses [
              {
                id = 1

                text = 'response 1'

                styles = {
                  style1 '<p>two four five</p>'
                  style2 '<p>dog cat mouse</p>'
                  style3 '<p>plane train motorbike</p>'
                }
              }
            ]
          }
        ])!
        

      it 'shows the differences between the original and updated styles, for each lexeme changed'
        lexemes = [{
          query = {
            id = '1'
          }
          response = {
            id = '1'
            styles {
              style1 '<p>one two three four six</p>'
              style2 '<p>dog cat mouse</p>'
              style3 '<p>walk plane motorbike</p>'
            }
            changedStyles = {
              style1 = true
              style2 = false
              style3 = true
            }
          }
        }]

        document = api.post!('/api/user/documents', {
          lexemes = lexemes
        }).body

        retry!
          expect(smtpServer.emails.length).to.equal 1

        email = smtpServer.emails.0

        (content) hasRelevantInfo =
          expect(content).to.contain('query 1')
          expect(content).to.contain('response 1')
          expect(content).to.contain('walk')
          expect(content).to.contain('train')
          expect(content).to.contain('style1')
          expect(content).to.contain('style3')
          expect(content).to.not.contain('style2')
          expect(content).to.contain("http://localhost:#(port)/admin/users/bob")
          expect(content).to.contain("http://localhost:#(port)/authoring/blocks/1/queries/1")

        (email.html) hasRelevantInfo
        (email.text) hasRelevantInfo
