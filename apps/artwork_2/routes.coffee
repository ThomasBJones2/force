qs = require 'qs'
{ extend } = require 'underscore'
metaphysics = require '../../lib/metaphysics'
{ METAPHYSICS_ENDPOINT } = require('sharify').data

query = """
  query artwork($id: String!) {
    artwork(id: $id) {
      ... meta
      ... banner
      ... images
      ... deep_zoom
      ... actions
      ... metadata
      ... inquiry
      ... auction
      ... highlights
      ... tabs
      ... artists
    }
  }
  #{require './components/meta/query'}
  #{require './components/banner/query'}
  #{require './components/images/query'}
  #{require './components/deep_zoom/query'}
  #{require './components/actions/query'}
  #{require './components/metadata/query'}
  #{require './components/inquiry/query'}
  #{require './components/auction/query'}
  #{require './components/highlights/query'}
  #{require './components/tabs/query'}
  #{require './components/artists/query'}
"""

helpers = extend [
  {}
  banner: require './components/banner/helpers'
  actions: require './components/actions/helpers'
  metadata: require './components/metadata/helpers'
  auction: require './components/auction/helpers'
  highlights: require './components/highlights/helpers'
  artists: require './components/artists/helpers'
  tabs: require './components/tabs/helpers'
  partner: require './components/partner/helpers'
]...

bootstrap = ->
  require('./components/banner/bootstrap') arguments...
  require('./components/actions/bootstrap') arguments...
  require('./components/inquiry/bootstrap') arguments...
  require('./components/auction/bootstrap') arguments...
  require('./components/deep_zoom/bootstrap') arguments...
  require('./components/partner/bootstrap') arguments...

@index = (req, res, next) ->
  send = query: query, variables: req.params

  return if metaphysics.debug req, res, send

  metaphysics send
    .then (data) ->
      extend res.locals.helpers, helpers
      bootstrap res.locals.sd, data
      res.render 'index', data

    .catch next
