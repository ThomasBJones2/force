_ = require 'underscore'
qs = require 'querystring'
Backbone = require 'backbone'
Notifications = require '../../../collections/notifications.coffee'
Artworks = require '../../../collections/artworks.coffee'
Artist = require '../../../models/artist.coffee'
ArtworkColumnsView = require '../../../components/artwork_columns/view.coffee'
DateHelpers = require '../../../components/util/date_helpers.coffee'
artistTemplate = -> require('../templates/artist.jade') arguments...
emptyTemplate = -> require('../templates/empty.jade') arguments...

module.exports = class RecentlyAddedWorksView extends Backbone.View
  columnViews: []

  initialize: ({@notifications, @filterState}) ->

    @$feed = @$('#notifications-feed')
    @$pins = @$('#notifications-pins')

    @listenTo @notifications, 'sync', @appendArtworks
    @filterState.on 'change', @render

    @setup =>
      @notifications.getFirstPage()?.then @checkIfEmpty

  setup: (cb) ->
    { artist_id } = @params()

    return cb() unless artist_id?

    @pinnedArtist = new Artist id: artist_id
    @pinnedArtworks = @pinnedArtist.related().artworks

    $.when.apply(null, [
      @pinnedArtist.fetch()
      @pinnedArtworks.fetch(data: size: 6, sort: '-published_at')
    ])?.then =>
      @$pins.html $container = @renderContainerTemplate(@pinnedArtist, @pinnedArtworks)
      @renderColumns $container.find('.notifications-published-artworks'), @pinnedArtworks
      @scrollToPins()
      cb()
    , cb # Ignore errors

  params: ->
    qs.parse(location.search.substring(1))

  appendArtworks: ->
    if @notifications.state.currentPage is 1
      @resetFeed()
    else
      @renderMethod = 'append'

    for artistName, publishedArtworks of @notifications.groupedByArtist()
      artworks = new Artworks @filterForPinned(publishedArtworks)
      continue unless artworks.length
      artist = new Artist artworks.first().get('artist')

      @$feed[@renderMethod] $container = @renderContainerTemplate(artist, artworks)
      # Only reset the DOM on the first iteration
      @renderMethod = 'append'

      @columnViews.push @renderColumns($container.find('.notifications-published-artworks'), artworks)

    $.waypoints 'refresh'

  filterForPinned: (artworks) ->
    return artworks unless @pinnedArtworks?.length
    @pinnedIds ?= @pinnedArtworks.pluck 'id'
    _.reject artworks, (artwork) =>
      _.contains @pinnedIds, artwork.id

  renderContainerTemplate: (artist, artworks) ->
    $ artistTemplate
      artist: artist
      publishedAt: @publishedAt(artworks)
      count: artworks.length

  publishedAt: (artworks) ->
    if (timestamps = _.map _.compact(artworks.pluck('published_changed_at')), Date.parse).length
      DateHelpers.formatDate _.max(timestamps)

  renderColumns: ($el, artworks) ->
    new ArtworkColumnsView
      el: $el
      collection: artworks
      artworkSize: 'large'
      numberOfColumns: 3
      gutterWidth: 40
      allowDuplicates: true
      maxArtworkHeight: 600

  nextPage: =>
    @notifications.getNextPage(
      data: for_sale: @filterState.get('forSale')
    )?.then (response) ->
      unless response.length
        $.waypoints 'destroy'

  isEmpty: ->
    !@notifications.length and (!@pinnedArtworks?.length is !@filterState.get('forSale'))

  checkIfEmpty: =>
    @filterState.set(empty: true) if @isEmpty()

  attachScrollHandler: ->
    @$feed.waypoint (direction) =>
      @nextPage() if direction is 'down'
    , { offset: 'bottom-in-view' }

  scrollToPins: ->
    $('body,html').scrollTop @pinsOffset ?= @$pins.offset().top - $('#main-layout-header').height()

  resetFeed: ->
    # Remove any existing column views
    _.invoke @columnViews, 'remove'
    # Reset the DOM
    @renderMethod = 'html'
    @columnViews = []
    # Reset the waypoints
    $.waypoints 'destroy'
    @attachScrollHandler()

  render: =>
    return if @filterState.get 'artist'
    return unless @filterState.get 'loading'
    @$pins.hide() # Only relevant on initial load
    @notifications.getFirstPage(
      data: for_sale: @filterState.get('forSale')
      success: =>
        @filterState.set('loading', false)
    )?.then @checkIfEmpty