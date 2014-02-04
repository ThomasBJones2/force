_             = require 'underscore'
sinon         = require 'sinon'
Backone       = require 'backbone'
SaleArtwork   = require '../../models/sale_artwork'
{ fabricate } = require 'antigravity'

describe 'SaleArtwork', ->

  beforeEach ->
    sinon.stub Backone, 'sync'
    @saleArtwork = new SaleArtwork fabricate 'sale_artwork'

  afterEach ->
    Backone.sync.restore()

  describe '#currentBid', ->

    it 'formats the highest_bid_amount_cents', ->
      @saleArtwork.set highest_bid_amount_cents: 10000
      @saleArtwork.currentBid().should.equal '$100'

    it 'defaults to opening_bid_cents', ->
      @saleArtwork.set highest_bid_amount_cents: null, opening_bid_cents: 200
      @saleArtwork.currentBid().should.equal '$2'

  describe '#bidLabel', ->

    it 'is Current Bid if there is a bid placed', ->
      @saleArtwork.set highest_bid_amount_cents: 1000
      @saleArtwork.bidLabel().should.equal 'Current Bid'

    it 'is Starting Bid if there is not a current bid', ->
      @saleArtwork.unset 'highest_bid_amount_cents'
      @saleArtwork.bidLabel().should.equal 'Starting Bid'

  describe '#minBid', ->

    it 'formats the minimum bid', ->
      @saleArtwork.set minimum_next_bid_cents: 1000
      @saleArtwork.minBid().should.equal '$10.00'

  describe '#bidCount', ->

    it 'returns an empty string if 0', ->
      @saleArtwork.set bidder_positions_count: 0
      @saleArtwork.set highest_bid_amount_cents: 100
      @saleArtwork.bidCount().should.equal ''

    it 'returns bid count in singular form if 1', ->
      @saleArtwork.set bidder_positions_count: 1
      @saleArtwork.set highest_bid_amount_cents: 100
      @saleArtwork.bidCount().should.equal '1 bid'

    it 'returns bid count in plural form if greater than 1', ->
      @saleArtwork.set bidder_positions_count: 6
      @saleArtwork.set highest_bid_amount_cents: 100
      @saleArtwork.bidCount().should.equal '6 bids'

    it 'returns a blank string if attribute not present', ->
      @saleArtwork.unset 'bidder_positions_count'
      @saleArtwork.bidCount().should.equal ''

    it 'returns a blank string if highest_bid_amount_cents null', ->
      @saleArtwork.set bidder_positions_count: 6
      @saleArtwork.unset 'highest_bid_amount_cents'
      @saleArtwork.bidCount().should.equal ''

  describe '#formatBidsAndReserve', ->
    describe 'with no bids', ->
      it 'returns This work has a reserve if there is a reserve', ->
        @saleArtwork.set highest_bid_amount_cents: 100
        @saleArtwork.set bidder_positions_count: 0
        @saleArtwork.set reserve_status: 'reserve_not_met'
        @saleArtwork.formatBidsAndReserve().should.equal '(This work has a reserve)'

      it 'returns nothing if there is no reserve', ->
        @saleArtwork.set highest_bid_amount_cents: 100
        @saleArtwork.set bidder_positions_count: 0
        @saleArtwork.set reserve_status: 'no_reserve'
        @saleArtwork.formatBidsAndReserve().should.equal ''

    describe 'with bids', ->
      it 'returns only bid data if there is no reserve', ->
        @saleArtwork.set highest_bid_amount_cents: 100
        @saleArtwork.set bidder_positions_count: 2
        @saleArtwork.set reserve_status: 'no_reserve'
        @saleArtwork.formatBidsAndReserve().should.equal '(2 bids)'

      it 'returns bid count and reserve not met if reserve is not met', ->
        @saleArtwork.set highest_bid_amount_cents: 100
        @saleArtwork.set bidder_positions_count: 2
        @saleArtwork.set reserve_status: 'reserve_not_met'
        @saleArtwork.formatBidsAndReserve().should.equal '(2 bids, Reserve not met)'

      it 'returns bid count and reserve met if reserve is met', ->
        @saleArtwork.set highest_bid_amount_cents: 100
        @saleArtwork.set bidder_positions_count: 2
        @saleArtwork.set reserve_status: 'reserve_met'
        @saleArtwork.formatBidsAndReserve().should.equal '(2 bids, Reserve met)'

  describe '#pollForBidChange', ->

    it 'will poll until the highest bid on the sale artwork changes', (done) ->
      sinon.stub global, 'setInterval'
      setInterval.callsArg 0
      @saleArtwork.set highest_bid_amount_cents: 100
      @saleArtwork.pollForBidChange success: -> done()
      _.last(Backone.sync.args)[2].success()
      @saleArtwork.set highest_bid_amount_cents: 100
      _.last(Backone.sync.args)[2].success()
      @saleArtwork.set highest_bid_amount_cents: 200
      _.last(Backone.sync.args)[2].success()
      setInterval.restore()
