__modules = {}
__moduleInstances = {}

# Module events engine
__moduleEvents = {
  _globalHandlers: {}
  trigger: (moduleInstance, eventName, data) ->
    @_globalHandlers[moduleInstance.constructor.NAME]?[eventName]
      ?.fireWith moduleInstance, [data, eventName]
    moduleInstance._eventHandlers?[eventName]
      ?.fireWith moduleInstance, [data, eventName]
  bindGlobal: (eventName, moduleName, handler) ->
    (
      (
        @_globalHandlers[moduleName] or= {}
      )[eventName] or= $.Callbacks()
    ).add handler
  unbindGlobal: (eventName, moduleName, handler) ->
    @_globalHandlers[moduleName]?[eventName]?.remove handler
  bindLocal: (moduleInstance, eventName, handler) ->
    (
      (
        moduleInstance._eventHandlers or= {}
      )[eventName] or= $.Callbacks()
    ).add handler
  unbindLocal: (moduleInstance, eventName, handler) ->
    moduleInstance._eventHandlers?[eventName]?.remove handler
}


# Constants
DYNAMIC = 'dynamic'
GLOBAL = 'global'
LAMBDA_MODULE = 'LambdaModule'


# Utils
_whitespace = /\s+/
_splitToLines =  (str) -> _(str.split '\n').filter (i) -> i != ''
_notOption = (i) -> i not in [DYNAMIC, GLOBAL]
_genLambdaName = -> _.uniqueId LAMBDA_MODULE


# Base module class
class BaseModule

  constructor: (@root, settings) ->
    {EXPECTED_SETTINGS, DEFAULT_SETTINGS, NAME} = @constructor
    if existing = @root.data NAME
      return existing
    dataSettings = _.pick @root.data(), EXPECTED_SETTINGS
    @settings = _.extend {}, DEFAULT_SETTINGS, dataSettings, settings
    @root.data NAME, @
    @__bind()
    @updateTree()
    (__moduleInstances[NAME] or= []).push @
    @initializer?()

  updateTree: ->
    for name, element of @constructor.ELEMENTS when not element.dynamic
      @[name] = $ element.selector, (if element.global then document else @root)

  find: (args...) ->
    @root.find args...

  on: (eventName, handler) ->
    __moduleEvents.bindLocal @, eventName, handler

  off: (eventName, handler) ->
    __moduleEvents.unbindLocal @, eventName, handler
  
  fire: (eventName, data) ->
    __moduleEvents.trigger @, eventName, data

  setOption: (name, value) ->
    @settings[name] = value

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
      __moduleEvents.bindGlobal eventName, moduleName, @__fixHandler handler


class ModuleInfo

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
    lines = _splitToLines treeString
    @root lines.shift()
    for line in lines
      [selector, options] = _.map line.split('/'), $.trim
      options = (options or '').split _whitespace
      name = _.filter(options, _notOption)[0] or null
      @element selector, name, DYNAMIC in options, GLOBAL in options

  event: (eventName, elementName, handler) ->
    @Module.EVENTS.push {elementName, eventName, handler}

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    lines = _splitToLines eventsString
    for line in lines
      [eventName, elementName, handlerName] = line.split _whitespace
      @event eventName, elementName, handlerName
    
  moduleEvent: (eventName, moduleName, handler) ->
    @Module.MODULE_EVENTS.push {eventName, moduleName, handler}

  # Set all modules events module wants to handle 
  moduleEvents: (moduleEventsString) ->
    lines = _splitToLines moduleEventsString
    for line in lines
      [eventName, moduleName, handlerName] = line.split _whitespace
      @moduleEvent eventName, moduleName, handlerName
  
  # Set default module settings
  defaultSettings: (newDefaultSettings) ->
    _.extend @Module.DEFAULT_SETTINGS, newDefaultSettings

  expectSettings: (expectedSettings...) ->
    @Module.EXPECTED_SETTINGS = _.union @Module.EXPECTED_SETTINGS, _.flatten expectedSettings


window.module = (moduleName, builder) ->

  if builder is undefined
    builder = moduleName
    moduleName = _genLambdaName()
    lambdaModule = true

  newModule = class extends BaseModule

  newModule.NAME = moduleName
  newModule.LAMBDA = !!lambdaModule

  builder new ModuleInfo newModule

  for name, element of newModule.ELEMENTS when element.dynamic
    do (element) ->
      newModule::[name] = ->
        $ element.selector, (if element.global then document else @root)

  __modules[moduleName] = newModule

  if newModule.AUTO_INIT
    $ -> window.modules.init newModule.NAME

  unless lambdaModule
    parts = moduleName.split '.'
    theName = parts.pop()
    currentScope = window
    for part in parts
      currentScope = (currentScope[part] or= {})
    currentScope[theName] = newModule

  return newModule
  

window.modules =
  find: (moduleName) ->
    __moduleInstances[moduleName] or []
  on: (eventName, moduleName, callback) ->
    __moduleEvents.bindGlobal eventName, moduleName, callback
  off:  (eventName, moduleName, callback) ->
    __moduleEvents.unbindGlobal eventName, moduleName, callback
  init: (moduleName, context = document) ->
    selector = __modules[moduleName].ROOT_SELECTOR
    if selector
      for el in $(selector, context).add $(context).filter selector
        new __modules[moduleName] $ el
  initAll: (context = document) ->
    for moduleName, Module of __modules when Module.AUTO_INIT
      @init moduleName, context


_.extend $.fn, {
  module: (moduleName) ->
    if @length
      new __modules[moduleName] @first()
}
