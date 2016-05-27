module.exports = (page) ->
  post:
    complete: (req, res, next) ->
      res.send req.body

  get:
    index: (req, res, next) ->
      page
        .get()
        .then (data) ->
          res.render 'index', data

        .catch next

    complete: (req, res) ->
      unless req.user?
        return res.redirect 'back'

      res.render 'complete'