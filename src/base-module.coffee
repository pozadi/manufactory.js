class manufactory.BaseModule

  constructor: (root, settings) ->
    {EXPECTED_SETTINGS, DEFAULT_SETTINGS, NAME} = @constructor
    if existing = root.data NAME
      return existing
    (manufactory._instances[NAME] or= []).push @
    @root = root
    @root.data NAME, @
    dataSettings = _.pick (@root.data() or {}), EXPECTED_SETTINGS
    @settings = _.extend {}, DEFAULT_SETTINGS, dataSettings, settings
    @__createElements()
    @__bind()
    @initializer?()

  updateElements: ->
    for name, element of @constructor.ELEMENTS
      @["$#{name}"].update()

  find: (args...) ->
    @root.find args...

  setOption: (name, value) ->
    @settings[name] = value
    @

  __createElements: ->
    @$root = @root # alias
    for name, element of @constructor.ELEMENTS
      @["$#{name}"] = @__findElement element
      @["$$#{name}"] = @__buildDynamicElement element

  __findElement: (element) ->
    context = if element.global then document else @root
    result = $ element.selector, context
    result.update = ->
      @splice 0, @length
      @push el for el in $ element.selector, context
      @
    result

  __fixHandler: (handler) ->
    if typeof handler is 'string'
      handler = @[handler]
    handler = _.bind handler, @
    (args...) ->
      args.unshift @
      handler args...

  __bind: ->
    {ELEMENTS, EVENTS, MODULE_EVENTS} = @constructor
    for eventMeta in EVENTS
      {handler, eventName, elementName} = eventMeta
      (if !elementName or elementName is 'root' 
        @root
      else 
        @["$$#{elementName}"]).on eventName, @__fixHandler handler
    @

  @__dynamicElementMixin:
    byChild: (child) ->
      $(child).parents @selector
    byParent: (parent) ->
      $(parent).find @selector
    on: (eventName, handler) ->
      (if @global then $(document) else @module.root)
        .on eventName, @selector, handler

  __buildDynamicElement: (element) ->
    fn = (filter) ->
      if filter
        @__findElement(element).filter(filter)
      else
        @__findElement(element)
    _.extend(fn, {module: @}, element, @constructor.__dynamicElementMixin)
