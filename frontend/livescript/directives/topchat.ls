{ fabric } = require \fabric

require! \numeral

{ TimeMachine } = require '../utils/time-machine.ls'

module.exports = [->
  return {
    template-url: 'templates/directives/topchat.html',
    scope: {
      'threads': '='
    },
    link: (scope, element) ->
      time-machine = null
      # -----
      threads = scope.threads
      el = element[0]
      container = el.get-elements-by-class-name('topchat-container')[0]
      canvas-el = el.get-elements-by-class-name('the-canvas')[0]

      #canvas-el = document.get-element-by-id \the-canvas

      canvas = new fabric.Canvas canvas-el, {
        width: 750
        height: 650
        is-drawing-mode: no
      }

      hardcoded-positions = [
        {"x":440,"y":75},
        {"x":295,"y":88},
        {"x":196,"y":187},
        {"x":291,"y":430},
        {"x":449,"y":430},
        {"x":635,"y":306},
        {"x":596,"y":425},
        {"x":245,"y":307},
        {"x":661,"y":191},
        {"x":584,"y":88}
      ]

      
      if window.device-pixel-ratio
        c = canvas.get-element!
        w = c.width
        h = c.height
        c.set-attribute \width w * window.device-pixel-ratio
        c.set-attribute \height h * window.device-pixel-ratio

        c.get-context \2d .scale window.device-pixel-ratio, window.device-pixel-ratio

      random-int = (min, max, step = 1) ->
        (Math.floor(Math.random! * ((max - min + 1) / step)) * step) + min

      get-random-pos = ->
        boundaries =
          min-x: 75
          min-y: 50
          max-x: 825
          max-y: 450
          #min-x: -450
          #min-y: -250
          #max-x: 375
          #max-y: 200

        x: random-int boundaries.min-x, boundaries.max-x
        y: random-int boundaries.min-y, boundaries.max-y

      calculate-row = (index, factor) -> Math.floor index / factor
      calculate-col = (index, factor) -> index % factor
      #FUCK YEAH PARENTHESES
      calculate-position = (index, factor) -> {
        x: (150 * (calculate-col index, 2)) + ((canvas.width / 2) - 75)
        y: ((100 * (calculate-row index, 2)) + 50) + 100
      }

      images-loaded = 0

      make-thread = (thread, index) ->
        #pos = hardcoded-positions[index]
        pos = calculate-position index, 2

        group = new fabric.Group [] {
          left: pos.x
          top: pos.y
          width: 150
          height: 100
          origin-x: \center
          origin-y: \center
        }

        text = new fabric.Text thread.target.name, {
          left: 0
          top: 20
          font-size: 14
          font-family: \Roboto
          text-align: \center
          origin-x: \center
          origin-y: \center
        }

        text-counter = numeral thread.message_count
          .format(\0a) ++ " " ++ do ->
            | thread.message_count < 2 => \mensagem
            | otherwise                => \mensagens

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

        text.has-controls = no
        text-counter.has-controls = no
        group.has-controls = no

        fabric.Image.fromURL thread.target.big_image_src, (o-img) !->
          images-loaded++

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

          if images-loaded is threads.length
            time-machine := new TimeMachine(canvas)


        group.add text, counter

      threads-group = [ make-thread thread, k for thread, k in threads ]

      [ canvas.add obj for obj in threads-group ]

      i-text = new fabric.IText 'esses são os amigos com quem mais converso' {
        left: 375
        top: 40
        padding: 7
        font-size: 30
        font-family: \Roboto
        origin-y: \center
        origin-x: \center
      }

      canvas.add i-text

      scope.toggle-free-draw = ->
        console.log("xd")
        canvas.is-drawing-mode = !canvas.is-drawing-mode

      scope.redo = -> time-machine.redo!

      scope.undo = -> time-machine.undo!

  }

]