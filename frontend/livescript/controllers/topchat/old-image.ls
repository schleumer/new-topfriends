{ reverse, take, sort-by } = require 'prelude-ls'


module.exports = [
  '$scope', '$rootScope', '$location', 'topchatThreads', '$http',
  ($scope, $root-scope, $location, topchat-threads, $http) !->
    threads = topchat-threads.get!
    $scope.status = 0

    if not threads.items.length
      $location.path("/topchat")

    me = threads.me
    threads = threads.items |> sort-by (.message_count) |> reverse
    
    if threads.length
      lang = window.navigator.userLanguage || window.navigator.language
      if lang != "pt-BR"
        lang = "en"
      else
        lang = "pt"
      new-threads = (threads.map ((x) ->
        {
          MessageCount: x.message_count
          OtherUser: ([x.target].map ((y) ->
            {
              FbId: y.fbid.toString!
              Id: y.id
              ImageUrl: 'http://graph.facebook.com/' + y.fbid.toString! + '/picture?width=120'
              Name: y.name
              ShortName: y.short_name
            })).pop!
          OtherUserId: x.target.fbid.toString!
          Participants: x.realParticipants.map ((z) ->
            {
              FbId: z.fbid.toString!
              Id: z.id
              ImageUrl: 'http://graph.facebook.com/' + z.fbid.toString! + '/picture?width=120'
              Name: z.name
              ShortName: z.short_name
            })
        }))

      $scope.status = 1

      $http({
        url:"http://api.topfriends.biz/v1?me=#{me}&columnSize=2&maxFriends=10&showRanking=1&lang=#{lang}",
        data: new-threads,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        }
      }).then((res) ->
        $scope.status = 2
        $scope.image = res.data
      )


    $scope.back = !-> $location.path('/topchat')
]
