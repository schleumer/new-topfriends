module.exports = [
  '$scope', '$rootScope', 'topchatThreads',
  ($scope, $root-scope, topchat-threads) ->
    console.log(topchat-threads.get!)
]