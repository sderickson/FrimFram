# http://stackoverflow.com/a/10865271/4240939
# https://gist.github.com/branneman/8048520#7-the-wrapper
# having a global require helps shorten require paths sometimes

# TODO: Rename projRequire to rootRequire I think
GLOBAL.rootDir = __dirname.replace('/server', '/')
GLOBAL.projRequire = (module) -> require(rootDir + module)
module.exports = projRequire