#TODO: TODO

export class TimeMachine
  (@canvas) ->
    @current = void
    @list = []
    @state = []
    @index = 0
    @index2 = 0
    @action = false
    @refresh = true

    @canvas.on 'object:added', (e) ~>
      object = e.target
      if @action is true
        @state = [@state[@index2]]
        @list = [@list[@index2]]
        @action = false
        @index = 1
      object.saveState!
      delete object.originalState.background-color
      @state[@index] = JSON.stringify object.originalState
      console.log(@state[@index])
      @list[@index] = object
      @index = @index + 1
      @index2 = @index - 1
      @refresh = true

    @canvas.on 'object:modified', (e) ~>
      object = e.target
      if @action is true
        @state = [@state[@index2]]
        @list = [@list[@index2]]
        @action := false
        @index := 1
      object.saveState!
      delete object.originalState.background-color
      @state[@index] = JSON.stringify object.originalState
      console.log(@state[@index])
      @list[@index] = object
      @index := @index + 1
      @index2 := @index - 1
      @refresh := true

  undo: ->
    if @index <= 0
      @index = 0
      return 
    if @refresh is true
      @index = @index - 1
      @refresh = false
    @index2 = @index - 1
    @current = @list[@index2]
    @current.setOptions JSON.parse @state[@index2]
    @index = @index - 1
    @current.setCoords!
    @canvas.renderAll!
    @action = true

  redo: ->
    @action = true
    return  if @index >= @state.length - 1
    @index2 = @index + 1
    @current = @list[@index2]
    @current.setOptions JSON.parse @state[@index2]
    @index = @index + 1
    @current.setCoords!
    @canvas.renderAll!