sysPath = require 'path'
startsWith = (string, substring) ->
  string.lastIndexOf(substring, 0) is 0

exports.config =
  paths:
    'public': 'public'
    
  conventions:
    ignored: (path) -> startsWith(sysPath.basename(path), '_')

  sourceMaps: true

  files:
  
    javascripts:
      defaultExtension: 'coffee'
      joinTo:
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^(vendor|bower_components)/
        'javascripts/test-app.js': /^test[\/\\]app/
        'javascripts/demo-app.js': /^test[\/\\]demo/

      order:
        before: [
          'bower_components/jquery/dist/jquery.js'
          'bower_components/lodash/dist/lodash.js'
          'bower_components/backbone/backbone.js'
          'bower_components/bootstrap/dist/bootstrap.js'
          'bower_components/tv4/tv4.js'
         ]
        
    stylesheets:
      defaultExtension: 'sass'
      joinTo:
        'stylesheets/app.css': /^(app|vendor|bower_components)/
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
          level: 'error'
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

  onCompile: (files) ->
    exec = require('child_process').exec
    regexFrom = '\\/\\/# sourceMappingURL=([^\\/].*)\\.map'
    regexTo = '\\/\\/# sourceMappingURL=\\/javascripts\\/$1\\.map'
    regex = "s/#{regexFrom}/#{regexTo}/g"
    for file in files
      c = "perl -pi -e '#{regex}' #{file.path}"
      exec c
