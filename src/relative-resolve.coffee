fs = require 'fs'
path = require 'path'

{sync: resolve} = require 'resolve'

CORE_MODULES = require './core-modules'
isCore = require './is-core'
canonicalise = require './canonicalise'

resolvePath = ({extensions, aliases, root, cwd, path: givenPath}, pkgMainField = 'browser') ->
  packageFilter = (pkg) ->
    if typeof pkg[pkgMainField] == 'string'
      pkg.main = pkg[pkgMainField]
    else if typeof pkg[pkgMainField] == 'object'
      for own k, v of pkg[pkgMainField]
        if v == pkg.main
          pkg.main = v
          break
    return pkg
  aliases ?= {}
  if isCore givenPath
    return if {}.hasOwnProperty.call aliases, givenPath
    corePath = CORE_MODULES[givenPath]
    unless fs.existsSync corePath
      throw new Error "Core module \"#{givenPath}\" has not yet been ported to the browser"
    givenPath = corePath
  # try regular CommonJS requires
  try
    resolve givenPath, {extensions, basedir: cwd or root, packageFilter}
  catch e
    # support non-standard root-relative requires
    try
      resolve (path.join root, givenPath), {extensions, packageFilter}
    catch e
      console.error(e)
      err = new Error "Cannot find module \"#{givenPath}\" in \"#{root}\""
      while cwd != '/'
        pkg_path = path.join cwd, 'package.json'
        if fs.existsSync pkg_path
          pkg = JSON.parse fs.readFileSync pkg_path, 'utf8'
          if 'browser' of pkg
            for own k, v of pkg['browser']
              if k == givenPath and not v
                return null
          break
        cwd = path.dirname cwd
      throw err


module.exports = ({extensions, aliases, root, cwd, path: givenPath}) ->
  aliases ?= {}
  resolved = resolvePath {extensions, aliases, root, cwd, path: givenPath}
  if resolved
    canonicalName = canonicalise root, resolved
    if {}.hasOwnProperty.call aliases, canonicalName
      resolved = aliases[canonicalName] and resolvePath {extensions, aliases, root, path: aliases[canonicalName]}
    {filename: resolved, canonicalName}
  else
    null
