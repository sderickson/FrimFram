// http://stackoverflow.com/questions/13176245/automate-jasmine-node-and-express-js


//- setup coffeescript support 
require('coffee-script');
require('coffee-script/register');

//- modify config so the server runs in test mode
var config = require('../server/server-config');
config.runningTests = true;
config.port = 3001;

//- start the server
var spawn = require('child_process').spawn;
server = require('../server/server');
server.start(function() {
  
  //- once the server is started, spawn jasmineNode in a separate process,
  // so we can cleanly close the server when it's done
  jasmineNode = spawn('node_modules/jasmine-node/bin/jasmine-node', ['test/server/', '--coffee', '--captureExceptions', '--forceexit']);
  logToConsole = function (data) { console.log(String(data)) };
  jasmineNode.stdout.on('data', logToConsole);
  jasmineNode.stderr.on('data', logToConsole);
  jasmineNode.on('exit', function (exitCode) { server.close() });
});
