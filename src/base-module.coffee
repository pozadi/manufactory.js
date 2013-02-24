class manufactory.BaseModule

  constructor: (root, settings) ->
    {EXPECTED_SETTINGS, DEFAULT_SETTINGS, NAME} = @constructor
    if existing = root.data NAME
      return existing
    (manufactory._instances[NAME] or= []).push @
    @el = {root}
    @el.root.data NAME, @
    dataSettings = _.pick @el.root.data(), EXPECTED_SETTINGS
    @settings = _.extend {}, DEFAULT_SETTINGS, dataSettings, settings
    @__bind()
    @__createElements()
    @initializer?()

  updateElements: ->
    for name, element of @constructor.ELEMENTS when not element.dynamic
      @el[name].update()

  find: (args...) ->
    @el.root.find args...

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
    for name, element of @constructor.ELEMENTS
      if element.dynamic
        @el[name] = @__buildDynamicElement element
      else
        @el[name] = @__findElement element
    @

  __findElement: (element) ->
    $ element.selector, (if element.global then document else @el.root)

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
      (if global then $(document) else @el.root)
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

  __buildDynamicElement: (element) ->
    fn = (filter) => 
      result = @__findElement element
      if filter
        result.filter filter
      else
        result
    fn.selector = element.selector
    return _.extend(fn, @constructor.__dynamicElementMixin)