httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect
_ = require 'underscore'
Document = require '../../server/models/document'
startSmtpServer = require './smtpServer'
retry = require 'trytryagain'

describe 'documents'
  port = 12345
  api = httpism.api "http://bob:password@localhost:#(port)"
  server = nil

  beforeEach
    app.set 'apiUsers' {
      "bob:password" = {
        email = 'bob@example.com'
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
    emailsReceived = []

    beforeEach
      smtpServer := startSmtpServer {
        emailReceived(email) =
          emailsReceived.push(email)
      }
      app.set 'smtp url' (smtpServer.url)

    afterEach
      smtpServer.stop()
      
    it 'emails the administrator when a change is made to a response when first creating the document'
      api.post!('/api/user/documents', {
        lexemes = [
          {
            response = {
              styles {
                style1 = 'changed'
                style2 = 'not changed'
              }
              stylesChanged = {
                style1 = true
                style2 = false
              }
            }
          }
        ]
      })

      retry!
        expect(emailsReceived.length).to.equal 1
