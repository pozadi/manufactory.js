class manufactory.Module

  # Constants
  GLOBAL = 'global'

  # Utils
  whitespace = /\s+/
  splitToLines =  (str) -> _(str.split '\n').filter (i) -> i != ''
  notOption = (i) -> i not in [GLOBAL]

  selectorToName = (selector) ->
    $.camelCase selector
      .replace(/[^a-z0-9]+/ig, '-')
      .replace(/^-/, '')
      .replace(/-$/, '')
      .replace(/^js-/, '')

  @build = (moduleName) ->

    if moduleName
      @LAMBDA = false
      @NAME = moduleName
    else
      @LAMBDA = true
      @NAME = _.uniqueId 'LambdaModule'

    manufactory._modules[@NAME] = @

    @ELEMENTS = {}
    @EVENTS = []
    @DEFAULT_SETTINGS = {}
    @EXPECTED_SETTINGS = []
    @AUTO_INIT = true

    _.defer =>
      $ => @init() if @AUTO_INIT

  @init = (context = document) ->
    if @ROOT_SELECTOR
      for el in $(@ROOT_SELECTOR, context).add $(context).filter @ROOT_SELECTOR
        new @ $ el
    else
      []

  @autoInit = (value) ->
    @AUTO_INIT = value

  @root = (rootSelector) ->
    @ROOT_SELECTOR = $.trim(rootSelector)

  @element = (selector, name=null, global=false) ->
    if name is null
      name = selectorToName selector
    @ELEMENTS[name] = {selector, global}

  @tree = (treeString) ->
    lines = splitToLines treeString
    @root lines.shift()?.split('/')[0]
    for line in lines
      [selector, options] = _.map line.split('/'), $.trim
      options = (options or '').split whitespace
      name = _.filter(options, notOption)[0] or null
      if selector
        @element selector, name, GLOBAL in options

  @event = (eventName, elementName, handler) ->
    @EVENTS.push {elementName, eventName, handler}

  @events = (eventsString) ->
    lines = splitToLines eventsString
    for line in lines
      [eventName, elementName, handlerName] = line.split whitespace
      if not handlerName?
        handlerName = elementName
        elementName = 'root'
      @event eventName, elementName, handlerName
    
  @defaultSettings = (newDefaultSettings) ->
    _.extend @DEFAULT_SETTINGS, newDefaultSettings

  @expectSettings = (expectedSettings) ->
    @EXPECTED_SETTINGS = 
      _.union @EXPECTED_SETTINGS, expectedSettings.split whitespace

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
