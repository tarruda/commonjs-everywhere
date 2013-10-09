fs = require 'fs'
path = require 'path'

initialized = false

initSignalHandlers = ->
  if initialized then return
  initialized = true
  process.on 'exit', ->
    for own cachePath, cache of caches
      fs.writeFileSync cachePath, JSON.stringify cache

  process.on 'SIGINT', process.exit
  process.on 'SIGTERM', process.exit
  process.on 'uncaughtException', (e) ->
    # to be safe, remove all cache files
    for own cachePath of caches
      if fs.existsSync(cachePath)
        fs.unlinkSync(cachePath)
    throw e

caches = {}
defaultCachePath = path.join(process.cwd(), '.powerbuild~')

module.exports = (node = true, cachePath = defaultCachePath) ->
  if {}.hasOwnProperty.call(caches, cachePath) and
      (caches[cachePath].node or not node)
    return caches[cachePath]

  initSignalHandlers()

  if fs.existsSync cachePath
    caches[cachePath] = JSON.parse fs.readFileSync cachePath, 'utf8'

  if not caches[cachePath]
    caches[cachePath] =
      processed: {}
      uids: {next: 1, names: {}}
      node: node

  return caches[cachePath]
