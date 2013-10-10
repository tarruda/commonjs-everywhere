path = require 'path'

module.exports = (root, file) ->
  root = path.resolve root
  rv = "#{path.relative root, file}".replace /\\/g, '/'
  return rv
