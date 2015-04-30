#TODO: TODO

export class TimeMachine
  (@canvas) ->
    @state = []
    @index = 0
    @index2 = 0
    @action = false
    @refresh = true

    @canvas.on 'object:added', (e) ~>
      object = e.target
      if @action is true
        @state = [@state[@index2]]
        @action = false
        @index = 1
      object.saveState!
      @state[@index] = {
        state: JSON.stringify object.originalState.{top,left}
        object: object
      }
      @index = @index + 1
      @index2 = @index - 1
      @refresh = true

    @canvas.on 'object:modified', (e) ~>
      object = e.target
      if @action is true
        @state = [@state[@index2]]
        @action = false
        @index = 1
      object.saveState!
      @state[@index] = {
        state: JSON.stringify object.originalState.{top,left}
        object: object
      }
      @index = @index + 1
      @index2 = @index - 1
      @refresh = true

  undo: ->
    if @index <= 0
      @index = 0
      return 
    if @refresh is true
      @index = @index - 1
      @refresh = false
    @index2 = @index - 1
    
    current = @state[@index2]
    console.log(current)
    current.object.setOptions(JSON.parse(current.state))

    @index = @index - 1
    current.object.setCoords!
    
    @canvas.renderAll!
    @action = true

  redo: ->
    @action = true
    return  if @index >= @state.length - 1
    @index2 = @index + 1
    current = @state[@index2]
    current.object.setOptions(JSON.parse(current.state))

    @index = @index + 1
    current.object.setCoords!
    
    @canvas.renderAll!