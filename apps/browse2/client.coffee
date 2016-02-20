qs = require 'querystring'
Backbone = require 'backbone'
Params = require '../../components/commercial_filter/models/params.coffee'
Filter = require '../../components/commercial_filter/models/filter.coffee'
UrlHandler = require '../../components/commercial_filter/url_handler.coffee'
PaginatorView = require '../../components/commercial_filter/filters/paginator/paginator_view.coffee'
MediumFilterView = require '../../components/commercial_filter/filters/medium/medium_filter_view.coffee'
ArtworkColumnsView = require '../../components/artwork_columns/view.coffee'
sd = require('sharify').data

module.exports.init = ->
  params = new Params qs.parse(location.search.replace(/^\?/, ''))
  filter = new Filter params: params

  artworkView = new ArtworkColumnsView
    collection: filter.artworks
    el: $('.cf-artworks')
    allowDuplicates: true
    numberOfColumns: 3

  filter.artworks.on 'reset', -> artworkView.render()
  filter.on 'change:loading', -> $('.cf-artworks').attr 'data-loading', filter.get('loading')

  mediumsView = new MediumFilterView
    el: $('.cf-sidebar__mediums')
    params: params
    aggregations: filter.aggregations

  paginatorView = new PaginatorView
    el: $('.cf-pagination')
    params: params
    filter: filter

  urlHandler = new UrlHandler
    params: params

  Backbone.history.start pushState: true

  params.trigger 'change'