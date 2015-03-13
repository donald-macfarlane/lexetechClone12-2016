httpism = require 'httpism'
app = require '../../server/app'
expect = require 'chai'.expect
lexiconBuilder = require '../lexiconBuilder'

describe 'documents'
  port = 12345
  api = httpism.api "http://user:password@localhost:#(port)"
  server = nil
  db = nil
  lexicon = nil

  beforeEach
    db := app.get 'db'
    app.set 'apiUsers' { "user:password" = true }
    server := app.listen (port)
    lexicon := lexiconBuilder()
    db.clear()!

  afterEach
    server.close()

  it 'creates new documents with different URLs'
    response1 = api.post!('/api/user/documents')
    response2 = api.post!('/api/user/documents')

    expect(response1.headers.location).to.not.equal(response2.headers.location)
    expect(response1.body.href).to.equal(response1.headers.location)
    expect(response2.body.href).to.equal(response2.headers.location)

  it 'can create a document, and put updates to it'
    response = api.post!('/api/user/documents')
    docUrl = response.headers.location
    doc = response.body
    doc.query = 'blah'

    api.post!(docUrl, doc)

    expect(api.get!(docUrl).body).to.eql(doc)

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

  it 'remember the last document written to'
    expect(api.get!('/api/user/documents/last', exceptions = false).statusCode).to.eql 404

    response1 = api.post!('/api/user/documents', {
      query = '1'
    })

    expect(api.get!('/api/user/documents/last').body).to.eql {
      href = '/api/user/documents/1'
      query = '1'
      id = '1'
    }

    response2 = api.post!('/api/user/documents', {
      query = '2'
    })

    expect(api.get!('/api/user/documents/last').body).to.eql {
      href = '/api/user/documents/2'
      query = '2'
      id = '2'
    }

    api.post!(response1.headers.location, {
      query = '1, altered'
    })

    expect(api.get!('/api/user/documents/last').body).to.eql {
      href = '/api/user/documents/1'
      query = '1, altered'
      id = '1'
    }

    api.post!(response2.headers.location, {
      query = '2, altered'
    })

    expect(api.get!('/api/user/documents/last').body).to.eql {
      href = '/api/user/documents/2'
      query = '2, altered'
      id = '2'
    }