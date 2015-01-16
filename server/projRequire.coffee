# http://stackoverflow.com/a/10865271/4240939

f = require.main.filename
# TODO: Figure out a better way to get both the dev server and server test runner to work with this
# A way that doesn't depend on the project folder being named 'frimfram'.
projectDir = f.slice(0, f.indexOf('/frimfram')) + '/frimfram'

# old way
#projectDir = require.main.filename.replace('/index.js', '')

module.exports = GLOBAL.projRequire = (module) -> require(projectDir + '/' + module)