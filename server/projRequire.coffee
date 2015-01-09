# http://stackoverflow.com/a/10865271/4240939

projectDir = require.main.filename.replace('/index.js', '')

module.exports = GLOBAL.projRequire = (module) -> require(projectDir + '/' + module)