# WHAT THE F**KING F**K

{ fabric } = require \fabric
{ sort-by, reverse } = require \prelude-ls

require! \numeral

{ TimeMachine } = require '../utils/time-machine.ls'

module.exports = ['$location', '$route', '$rootScope', '$http', '$timeout', '$filter'
($location, $route, $root-scope, $http, $timeout, $filter) ->
  return {
    template-url: 'templates/directives/topchat.html',
    scope: {
      'threads': '=',
      'me': '='
    },
    link: (scope, element) -> $timeout ->
      scope.brush-size = 1
      scope.brush-color = "#000000"
      scope.message = null
      scope.message-class = null
      scope.message-spin = true
      canvas = null
      time-machine = null

      # -----
      threads = scope.threads |> sort-by (.message_count) |> reverse

      el = element[0]
      container = el.get-elements-by-class-name('topchat-container')[0]
      canvas-el = el.get-elements-by-class-name('the-canvas')[0]

      #canvas-el = document.get-element-by-id \the-canvas

      canvas := new fabric.Canvas canvas-el, {
        width: 900
        height: 650
        is-drawing-mode: no
      }

      scope.$watch 'brushColor' (new-val) ->
        canvas.free-drawing-brush.color = new-val

      scope.$watch 'brushSize' (new-val) ->
        console.log('xddd')
        canvas.free-drawing-brush.width = new-val

      document.add-event-listener "keydown" (e) ->
        switch e.keyCode
        | 46 => canvas.remove canvas.getActiveObject!


      window.add-event-listener "paste" (e) ->
        clip-data = event.clipboardData
        for item in clip-data.items
          type = item.type
          console.log(type)
          if type.index-of("image") is not -1
            data = item.get-as-file!
            image-url = window.URL.create-objectURL data
            fabric.Image.fromURL image-url, (o-img) !->
              o-img
                ..left     = 0
                ..top      = 0
                ..origin-x = \left
                ..origin-y = \top
                ..scale 1
              canvas.add o-img
              canvas.render-all!


      time-machine := new TimeMachine(canvas)

      
      if window.device-pixel-ratio
        c = canvas.get-element!
        w = c.width
        h = c.height
        c.set-attribute \width w * window.device-pixel-ratio
        c.set-attribute \height h * window.device-pixel-ratio

        c.get-context \2d .scale window.device-pixel-ratio, window.device-pixel-ratio

      random-int = (min, max, step = 1) ->
        (Math.floor(Math.random! * ((max - min + 1) / step)) * step) + min

      round-to-step = (number, x, o) -> ~~o + Math.ceil((number - o)/ x ) * x 

      calculate-row = (index, factor) -> Math.floor index / factor
      calculate-col = (index, factor) -> index % factor
      #FUCK YEAH PARENTHESES
      calculate-position = (index, factor) ->
        x: (150 * (calculate-col index, factor)) + ((((canvas.width / 150) - factor) * 75) + 75)
        y: ((100 * (calculate-row index, factor)) + 50) + 100

      make-thread = (thread, index) ->
        pos = calculate-position index, (round-to-step threads.length, 5by, 5from) / 5rows

        group = new fabric.Group [] {
          left: pos.x
          top: pos.y
          width: 150
          height: 100
          origin-x: \center
          origin-y: \center
        }

        group.id = "thread.#{thread.target.fbid}"

        text = new fabric.Text thread.target.name.to-lower-case!, {
          left: 0
          top: 20
          font-size: 14
          font-family: \Roboto
          text-align: \center
          origin-x: \center
          origin-y: \center
        }

        #text-counter = numeral thread.message_count
        #  .format(\0a) ++ " " ++ do ->
        #    | thread.message_count < 2 => \mensagem
        #    | otherwise                => \mensagens

        text-counter = $filter('plural')(thread.message_count, ['%s mensagem', '%s mensagens'])

        counter = new fabric.Text text-counter, {
          left: 0
          top: 40
          font-size: 14
          font-family: \Roboto
          text-align: \center
          font-style: \italic
          origin-y: \center
          origin-x: \center
        }

        group.has-controls = no

        path = encode-URI-component "/#{thread.target.fbid}/picture?width=64&height=64"
        fabric.Image.fromURL "/facebook-proxy?path=#{path}", (o-img) !->
          anti-crisp-circle = new fabric.Circle {
            stroke-width: 2,
            stroke: 'white'
            left: -26
            top: -44
            radius: 25
            fill: \transparent
          }

          o-img
            ..left     = 0
            ..top      = -18
            ..origin-x = \center
            ..origin-y = \center
            ..clip-to  = (ctx) -> 
              ctx.arc 0 0 25 0 2 * Math.PI
            ..scale 1

          group.add o-img, anti-crisp-circle
          canvas.render-all!
          time-machine.clear!
            


        group.add text, counter

      threads-group = [ make-thread thread, k for thread, k in threads ]

      [ canvas.add obj for obj in threads-group ]

      i-text = new fabric.IText 'esses são os amigos com quem mais converso' {
        left: 450
        top: 40
        padding: 7
        font-size: 30
        font-family: \Roboto
        origin-y: \center
        origin-x: \center
      }

      i-text.id = "title"

      #line = new fabric.Line([canvas.width / 2, 0, canvas.width / 2, canvas.height], {
      #  fill: \red,
      #  stroke: \red,
      #  stroke-width: 1
      #})
      #canvas.add line

      canvas.add i-text

      scope.toggle-free-draw = ->
        scope.is-drawing = !scope.is-drawing
        canvas.is-drawing-mode = scope.is-drawing

      scope.redo = -> time-machine.redo!

      scope.undo = -> time-machine.undo!

      scope.clear = -> $route.reload!

      scope.back = !-> $location.path('/topchat')

      scope.share = ->
        canvas.deactivateAll!renderAll!

        scope.url = null
        scope.message = "processando a imagem :)"
        scope.message-spin = true
        scope.message-class = "fa-cog"
        $http.post '/base64-proxy', {
          image: canvas.to-data-URL!
        } .then((res) ->
          scope.image-url = res.data
          scope.type = "emergency"
          scope.message = null
          #scope.url = null
          #scope.message-class = "fa-spinner"
          #scope.message-spin = true
          #scope.message = "enviando a imagem para o Facebook :D"
          #FB.api('/photos', 'post', {
          #  url: res.data
          #}, (response) ->
          #  scope.$apply ->
          #    scope.message-class = "fa-thumbs-up"
          #    scope.message-spin = false
          #    scope.message = "imagem postada com sucesso!"
          #    scope.url = "https://fb.com/#{response.id}"
          #    console.log response
          #);
        )

      scope.open = !->
        canvas.deactivateAll!renderAll!
        url = canvas.to-data-URL!
        window.open(url)


      scope.add-me = ->
        console.log scope
        # DAT URI
        path = encode-URI-component "/#{scope.me}/picture?width=128"
        fabric.Image.fromURL "/facebook-proxy?path=#{path}", (o-img) !->
          cool-group = new fabric.Group [] {
            left: canvas.width - 128
            top: (canvas.height - 64) / 2
            width: 128
            height: 128
            origin-x: \center
            origin-y: \center
          }

          anti-crisp-circle = new fabric.Circle {
            stroke-width: 2,
            stroke: 'white'
            left: 0
            top: 0
            radius: 64
            fill: \transparent
            origin-x: \center
            origin-y: \center
          }

          o-img
            ..left     = 0
            ..top      = 0
            ..origin-x = \center
            ..origin-y = \center
            ..clip-to  = (ctx) -> 
              ctx.arc 0 0 64 0 2 * Math.PI
            ..scale 1

          cool-group.add o-img, anti-crisp-circle
          canvas.add cool-group
          canvas.render-all!

  }

]