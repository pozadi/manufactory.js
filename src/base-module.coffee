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
    @__bind()
    @__createElements()
    @initializer?()

  updateElements: ->
    for name, element of @constructor.ELEMENTS
      @["$#{name}"].update()

  find: (args...) ->
    @root.find args...

  on: (eventName, handler) ->
    manufactory.callbacks.localCallbacks(@, eventName).add(handler)
    @

  off: (eventName, handler) ->
    manufactory.callbacks.localCallbacks(@, eventName).remove(handler)
    @

  fire: (eventName, data) ->
    manufactory.callbacks.trigger @, eventName, data
    @

  setOption: (name, value) ->
    @settings[name] = value
    @

  __createElements: ->
    @$root = @root # alias
    for name, element of @constructor.ELEMENTS
      @["$#{name}"] = @__findElement element
      @["$$#{name}"] = @__buildDynamicElement element

  __findElement: (element) ->
    $ element.selector, (if element.global then document else @root)

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
      {selector, global} = ELEMENTS[elementName]
      (if global then $(document) else @root)
        .on eventName, selector, @__fixHandler handler
    for eventMeta in MODULE_EVENTS
      {eventName, moduleName, handler} = eventMeta
      manufactory.callbacks.globalCallbacks(moduleName, eventName).add @__fixHandler handler
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
