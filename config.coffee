sysPath = require 'path'
fs = require('fs')
_ = require 'lodash'
commonjsHeader = fs.readFileSync('node_modules/brunch/node_modules/commonjs-require-definition/require.js', {encoding: 'utf8'})
regJoin = (s) -> new RegExp(s.replace(/\//g, '[\\\/\\\\]'))

exports.config =
  paths:
    'public': 'public'
    'watched': ['app', 'test/app', 'vendor', 'src']
    
  conventions:
    ignored: (path) -> _.startsWith(sysPath.basename(path), '_')
    vendor: /(vendor|src|bower_components)[\\/]/

  sourceMaps: true

  files:
  
    javascripts:
      defaultExtension: 'coffee'
      joinTo:
        'javascripts/frimfram.js': /^src/
        '../dist/frimfram.js': /^src/
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^(vendor|bower_components)/
        'javascripts/test-app.js': /^test[\/\\]app/
        'javascripts/demo-app.js': /^test[\/\\]demo/

      order:
        before: [
          'src/init.js'
          'src/BaseClass.coffee'
          'src/BaseView.coffee'
          'bower_components/jquery/dist/jquery.js'
          'bower_components/lodash/lodash.js'
          'bower_components/backbone/backbone.js'
          'bower_components/bootstrap/dist/bootstrap.js'
          'bower_components/tv4/tv4.js'
         ]
        
    stylesheets:
      defaultExtension: 'sass'
      joinTo:
        '../dist/frimfram.css': /^src/
        'stylesheets/app.css': /^(app|vendor|bower_components|src)/
      order:
        before: [
          'app/styles/bootstrap/*'
        ]

    templates:
      defaultExtension: 'jade'
      joinTo: 'javascripts/app.js'

  framework: 'backbone'

  plugins:
    autoReload:
      delay: 300

    coffeelint:
      pattern: /^app\/.*\.coffee$/
      options:
        line_endings:
          value: 'unix'
          level: 'ignore'
        max_line_length:
          level: 'ignore'
        no_unnecessary_fat_arrows:
          level: 'ignore'

    uglify:
      output:
        semicolons: false

    sass:
      mode: 'ruby'
      allowCache: true

  modules:
    definition: (path) ->
      if _(path).endsWith('app.js') then commonjsHeader else ''


  onCompile: (files) ->
    # TODO: update to the new setting
    exec = require('child_process').exec
    regexFrom = '\\/\\/# sourceMappingURL=([^\\/].*)\\.map'
    regexTo = '\\/\\/# sourceMappingURL=\\/javascripts\\/$1\\.map'
    regex = "s/#{regexFrom}/#{regexTo}/g"
    for file in files
      c = "perl -pi -e '#{regex}' #{file.path}"
      exec c
