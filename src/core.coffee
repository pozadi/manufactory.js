# Constants
DYNAMIC = 'dynamic'
GLOBAL = 'global'
LAMBDA_MODULE = 'LambdaModule'


# Utils
whitespace = /\s+/
splitToLines =  (str) -> _(str.split '\n').filter (i) -> i != ''
notOption = (i) -> i not in [DYNAMIC, GLOBAL]


manufactory = window.manufactory = {
  _modules: {}
  _instances: {}
  find: (moduleName) ->
    @_instances[moduleName] or []
  on: (eventName, moduleName, callback) ->
    @_events.globalCallbacks(moduleName, eventName).add(callback)
  off: (eventName, moduleName, callback) ->
    @_events.globalCallbacks(moduleName, eventName).remove(callback)
  init: (moduleName, context = document) ->
    selector = @_modules[moduleName].ROOT_SELECTOR
    if selector
      for el in $(selector, context).add $(context).filter selector
        new @_modules[moduleName] $ el
  initAll: (context = document) ->
    for moduleName, Module of @_modules when Module.AUTO_INIT
      @init moduleName, context
}


_.extend $.fn, {
  module: (moduleName) ->
    if @length
      new manufactory._modules[moduleName] @first()
}






# Base module class
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
    @__createDynamicElements()
    @updateElements()
    @initializer?()

  updateElements: ->
    for name, element of @constructor.ELEMENTS when not element.dynamic
      @el[name] = @__findElement element

  find: (args...) ->
    @el.root.find args...

  on: (eventName, handler) ->
    manufactory._events.localCallbacks(@, eventName).add(handler)

  off: (eventName, handler) ->
    manufactory._events.localCallbacks(@, eventName).remove(handler)

  fire: (eventName, data) ->
    manufactory._events.trigger @, eventName, data

  setOption: (name, value) ->
    @settings[name] = value

  __createDynamicElements: ->
    for name, element of @constructor.ELEMENTS when element.dynamic
      @el[name] = @__buildDynamicElement element

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
      manufactory._events.globalCallbacks(moduleName, eventName).add @__fixHandler handler

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



class manufactory.ModuleInfo

  selectorToName = (selector) ->
    $.camelCase selector
      .replace(/[^a-z0-9]+/ig, '-')
      .replace(/^-/, '')
      .replace(/-$/, '')
      .replace(/^js-/, '')

  constructor: (@Module) ->
    @Module.ELEMENTS = {}
    @Module.EVENTS = []
    @Module.MODULE_EVENTS = []
    @Module.DEFAULT_SETTINGS = {}
    @Module.EXPECTED_SETTINGS = []
    @Module.AUTO_INIT = true

  # Set all module events
  methods: (newMethods) ->
    _.extend @Module::, newMethods

  autoInit: (value) ->
    @Module.AUTO_INIT = value

  # Set root selector
  root: (rootSelector) ->
    @Module.ROOT_SELECTOR = rootSelector

  # Add element module interact with
  element: (selector, name=null, dynamic=false, global=false) ->
    if name is null
      name = selectorToName selector
    @Module.ELEMENTS[name] = {selector, dynamic, global}

  # Set root selector and all elements at once
  tree: (treeString) ->
    lines = splitToLines treeString
    @root lines.shift()
    for line in lines
      [selector, options] = _.map line.split('/'), $.trim
      options = (options or '').split whitespace
      name = _.filter(options, notOption)[0] or null
      @element selector, name, DYNAMIC in options, GLOBAL in options

  event: (eventName, elementName, handler) ->
    @Module.EVENTS.push {elementName, eventName, handler}

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    lines = splitToLines eventsString
    for line in lines
      [eventName, elementName, handlerName] = line.split whitespace
      @event eventName, elementName, handlerName
    
  moduleEvent: (eventName, moduleName, handler) ->
    @Module.MODULE_EVENTS.push {eventName, moduleName, handler}

  # Set all modules events module wants to handle 
  moduleEvents: (moduleEventsString) ->
    lines = splitToLines moduleEventsString
    for line in lines
      [eventName, moduleName, handlerName] = line.split whitespace
      @moduleEvent eventName, moduleName, handlerName
  
  # Set default module settings
  defaultSettings: (newDefaultSettings) ->
    _.extend @Module.DEFAULT_SETTINGS, newDefaultSettings

  expectSettings: (expectedSettings) ->
    @Module.EXPECTED_SETTINGS = _.union @Module.EXPECTED_SETTINGS, expectedSettings.split whitespace


manufactory.module = (moduleName, builder) ->

  # Call with one argument:
  #   manufactory.module ->
  #     ...
  if builder is undefined
    builder = moduleName
    moduleName = _.uniqueId LAMBDA_MODULE
    lambdaModule = true

  newModule = class extends manufactory.BaseModule

  newModule.NAME = moduleName
  newModule.LAMBDA = !!lambdaModule

  builder new manufactory.ModuleInfo newModule

  manufactory._modules[moduleName] = newModule

  if newModule.AUTO_INIT
    $ -> manufactory.init newModule.NAME

  unless lambdaModule
    parts = moduleName.split '.'
    theName = parts.pop()
    currentScope = window
    for part in parts
      currentScope = (currentScope[part] or= {})
    currentScope[theName] = newModule

  return newModule
  

manufactory._events = {
  _globalHandlers: {}
  trigger: (moduleInstance, eventName, data) ->
    for callbacks in [
      @localCallbacks(moduleInstance, eventName), 
      @globalCallbacks(moduleInstance.constructor.NAME, eventName)
    ]
      callbacks.fireWith moduleInstance, [data, eventName]
  localCallbacks: (moduleInstance, eventName) ->
    (moduleInstance.__eventHandlers or= {})[eventName] or= $.Callbacks()
  globalCallbacks: (moduleName, eventName) ->
    (@_globalHandlers[moduleName] or= {})[eventName] or= $.Callbacks()
}
