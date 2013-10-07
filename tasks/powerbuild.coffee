_ = require 'lodash'
path = require 'path'
Powerbuild = require '../src'
buildCache = require '../src/build-cache'


NAME = 'powerbuild'
DESC = 'Wraps node.js/commonjs projects into single umd function that will run
 anywhere, generating concatenated source maps to debug files individually.'


module.exports = (grunt) ->
  grunt.registerMultiTask NAME, DESC, ->
    options = @options()
    for f in @files
      opts = _.clone(options)
      if not opts.disableDiskCache
        cache = buildCache(opts.cachePath)
        opts.processed = cache.processed
        opts.uids = cache.uids
      opts.entryPoints = grunt.file.expand(f.orig.src)
      opts.output = f.dest
      build = new Powerbuild(opts)
      start = new Date().getTime()
      grunt.log.ok("Build started...")
      {code, map} = build.bundle()
      console.error("Completed in #{new Date().getTime() - start} ms")
      grunt.file.write build.output, code
      grunt.log.ok("Created #{build.output}")
      if build.sourceMap
        grunt.file.write build.sourceMap, map
        grunt.log.ok("Created #{build.sourceMap}")
