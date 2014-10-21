{ fabricate } = require 'antigravity'
_ = require 'underscore'
sinon = require 'sinon'
Backbone = require 'backbone'
routes = require '../routes'
CurrentUser = require '../../../models/current_user.coffee'
Artist = require '../../../models/artist.coffee'
sections = require '../sections'

describe 'sections', ->
  it 'returns the correct tab slugs in the correct order', ->
    sections.should.eql ['works', 'posts', 'shows', 'press', 'collections', 'related-artists']

describe 'Artist routes', ->
  beforeEach ->
    sinon.stub Backbone, 'sync'
    @req =
      params: id: 'foo'
      query: sort: '-published_at'
    @res =
      render: sinon.stub()
      redirect: sinon.stub()
      header: sinon.stub()
      write: sinon.stub()
      end: sinon.stub()
      locals: sd: APP_URL: 'http://localhost:5000', CURRENT_PATH: '/artist/andy-foobar'

  afterEach ->
    Backbone.sync.restore()

  describe '#index', ->
    it 'renders the artist template', (done) ->
      routes.index @req, @res
      Backbone.sync.args[0][2].success fabricate 'artist', id: 'andy-foobar'
      Backbone.sync.args[1][2].success()
      _.defer =>
        @res.render.args[0][0].should.equal 'index'
        @res.render.args[0][1].artist.get('id').should.equal 'andy-foobar'
        done()

    it 'bootstraps the artist', (done) ->
      routes.index @req, @res
      Backbone.sync.args[0][2].success fabricate 'artist', id: 'andy-foobar'
      Backbone.sync.args[1][2].success()
      _.defer =>
        @res.locals.sd.ARTIST.id.should.equal 'andy-foobar'
        done()

    it 'redirects to canonical url', (done) ->
      @res.locals.sd.CURRENT_PATH = '/artist/bar'
      routes.index @req, @res
      Backbone.sync.args[0][2].success fabricate 'artist', id: 'andy-foobar'
      Backbone.sync.args[1][2].success()
      _.defer =>
        @res.redirect.args[0][0].should.equal '/artist/andy-foobar'
        done()

  describe '#follow', ->
    it 'redirect to artist page without user', ->
      routes.follow @req, @res
      @res.redirect.args[0][0].should.equal '/artist/foo'

    it 'follows an artist and redirects to the artist page', ->
      @res.redirect = sinon.stub()
      @req.user = new CurrentUser fabricate 'user'
      routes.follow @req, @res
      Backbone.sync.args[0][1].url().should.containEql '/api/v1/me/follow/artist'
      Backbone.sync.args[0][1].get('artist_id').should.equal 'foo'
      Backbone.sync.args[0][2].success()
      @res.redirect.args[0][0].should.equal '/artist/foo'

  # Temporary
  describe '#data', ->
    it 'returns the example data when it has it available', ->
      @req = params: id: 'sterling-ruby', section: 'bibliography'
      routes.data @req, @res
      JSON.parse(@res.write.args[0][0].toString())[0].artist_id.should.equal 'sterling-ruby'

    it 'returns an empty array when it does not have anything available', ->
      @req = params: id: 'damon-zucconi', section: 'bibliography'
      routes.data @req, @res
      response = JSON.parse(@res.write.args[0][0].toString())
      response.should.be.instanceOf Array
      response.length.should.equal 0
