__modules = {}
__moduleInstances = {}
__moduleEvents = {
  _globalHandlers: {}
  trigger: (moduleInstance, eventName, data) ->
    globalHandlers = @_globalHandlers[moduleInstance.constructor.NAME]?[eventName] or []
    localHandlers = moduleInstance._eventHandlers?[eventName] or []
    for handler in _.union localHandlers, globalHandlers
      handler.call moduleInstance, data, eventName
  bindGlobal: (eventName, moduleName, handler) ->
    @_globalHandlers[moduleName] or= {}
    @_globalHandlers[moduleName][eventName] or= []
    @_globalHandlers[moduleName][eventName].push handler
  unbindGlobal: (eventName, moduleName, handler) ->
    return unless @_globalHandlers[moduleName]?[eventName]
    handlers = _.without @_globalHandlers[moduleName][eventName], handler
    @_globalHandlers[moduleName][eventName] = handlers
  bindLocal: (moduleInstance, eventName, handler) ->
    moduleInstance._eventHandlers or= {}
    moduleInstance._eventHandlers[eventName] or= []
    moduleInstance._eventHandlers[eventName].push handler
  unbindLocal: (moduleInstance, eventName, handler) ->
    return unless moduleInstance._eventHandlers?[eventName]
    handlers = _.without moduleInstance._eventHandlers[eventName], handler
    moduleInstance._eventHandlers[eventName] = handlers
}

LAZY = 'lazy'
LOAD = 'load'
NONE = 'none'
DYNAMIC = 'dynamic'
HTML_INSERTED = 'html-inserted'
LAMBDA_MODULE = 'LambdaModule'

class BaseModule

  constructor: (@root, settings) ->
    @settings = $.extend {}, @constructor.DEFAULT_SETTINGS
    data = @root.data()
    for option in @constructor.EXPECTED_SETTINGS
      if data[option] != undefined
        @settings[option] = data[option]
    $.extend @settings, settings
    @root.data @constructor.NAME, @
    @_bind() unless @constructor.INIT is LAZY
    @updateTree()
    @root.on HTML_INSERTED, => @updateTree()
    if __moduleInstances[@constructor.NAME] is undefined
      __moduleInstances[@constructor.NAME] = []
    __moduleInstances[@constructor.NAME].push @
    @initializer?()

  updateTree: ->
    for name, element of @constructor.ELEMENTS when not element.dynamic
      @[name] = @find element.selector

  _fixHandler: (handler) ->
    if typeof handler is 'string'
      handler = @[handler]
    handler = _.bind handler, @
    (args...) ->
      args.unshift @
      handler args...

  @_fixHandler: (handler) ->
    moduleClass = @
    (args...) ->
      rootElement = $(@).parents moduleClass.ROOT_SELECTOR
      moduleInstance = rootElement.module moduleClass.NAME
      handler = moduleInstance._fixHandler handler
      handler.apply @, args

  @_fixHandlerAlt: (handler) ->
    moduleClass = @
    (args...) ->
      for rootElement in $ moduleClass.ROOT_SELECTOR
        moduleInstance = $(rootElement).module moduleClass.NAME
        _handler = moduleInstance._fixHandler handler
        _handler.apply @, args

  @_nameToSelector: (name) ->
    @ELEMENTS[name].selector

  _bind: ->
    for eventMeta in @constructor.EVENTS
      {handler, eventName, elementName} = eventMeta
      selector = @constructor._nameToSelector elementName
      @root.on eventName, selector, @_fixHandler handler
    for eventMeta in @constructor.GLOBAL_EVENTS
      {eventName, selector, handler} = eventMeta
      $(document).on eventName, selector, @_fixHandler handler
    for eventMeta in @constructor.MODULE_EVENTS
      {eventName, moduleName, handler} = eventMeta
      __moduleEvents.bindGlobal eventName, moduleName, @_fixHandler handler

  @_bind: ->
    for eventMeta in @EVENTS
      {handler, eventName, elementName} = eventMeta
      selector = @_nameToSelector elementName
      selector = "#{@ROOT_SELECTOR} #{selector}"
      do (eventName, selector, handler) =>
        $(document).on eventName, selector, @_fixHandler handler
    for eventMeta in @GLOBAL_EVENTS
      {eventName, selector, handler} = eventMeta
      $(document).on eventName, selector, @_fixHandlerAlt handler

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


class ModuleInfo

  constructor: ->
    @_methods = {}
    @_elements = {}
    @_events = []
    @_globalEvents = []
    @_moduleEvents = []
    @_defaultSettings = {}
    @_expectedSettings = []
    @_init = 'none'

  # Set all module events
  methods: (newMethods) ->
    $.extend @_methods, newMethods

  # Set initialization mode
  # Takes one of
  #  'load'
  #  'lazy'
  #  'none'
  init: (value) ->
    @_init = value

  # Set root selector
  root: (rootSelector) ->
    @_rootSelector = rootSelector

  # `div` → `div`  
  # `@button` → `button`
  # `.button` → `button`
  # `@button a` → `buttonA`
  # `@my-button` → `myButton`
  # `input[type=text]` → `inputTypeText`
  #
  # Split to words (delimetr is all not letters and not digits characters) 
  # then join words in mixedCase notation.
  @selectorToName: (selector) ->
    first = true
    (for word in selector.split /[^a-z0-9]+/i when word != ''
      if first
        first = false
        word
      else
        word.charAt(0).toUpperCase() + word.slice(1)
    ).join ''

  # Add element module interact with
  element: (selector, name=null, dynamic=false) ->
    if name is null
      name = @constructor.selectorToName selector
    @_elements[name] = {selector, dynamic}

  # Set root selector and all elements at once
  tree: (treeString) ->
    lines = _(treeString.split '\n').map($.trim).filter (l) -> l != '' 
    @root lines.shift()
    for line in lines
      [selector, options] = _.map line.split('/'), $.trim
      if options
        [name, options...] = options.split /\s+/
        name = $.trim name
        options = _.map options, $.trim
      else
        name = null
        options = []
      @element selector, name, DYNAMIC in options

  event: (eventName, elementName, handler) ->
    @_events.push {elementName, eventName, handler}

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    lines = _(eventsString.split '\n').map($.trim).filter (l) -> l != ''
    for line in lines
      [eventName, elementName, handlerName] = _(line.split /\s+/).map($.trim)
      @event eventName, elementName, handlerName
    
  moduleEvent: (eventName, moduleName, handler) ->
    @_moduleEvents.push {eventName, moduleName, handler}

  # Set all modules events module wants to handle 
  moduleEvents: (moduleEventsString) ->
    lines = _(moduleEventsString.split '\n').map($.trim).filter (l) -> l != ''
    for line in lines
      [eventName, moduleName, handlerName] = _(line.split /\s+/).map($.trim)
      @moduleEvent eventName, moduleName, handlerName

  globalEvent: (eventName, selector, handler) ->
    @_globalEvents.push {eventName, selector, handler}

  # Set all global DOM events module wants to handle
  globalEvents: (globalEventsString) ->
    # TODO
  
  # Set default module settings
  defaultSettings: (newDefaultSettings) ->
    $.extend @_defaultSettings, newDefaultSettings

  expectSettings: (expectedSettings...) ->
    @_expectedSettings = _.union @_expectedSettings, _.flatten expectedSettings

  # 
  extends: (moduleName) ->
    # TODO

lastNameId = 0
genLambdaName = -> 
  "#{LAMBDA_MODULE}#{lastNameId++}"

buildModule = (moduleName, builder) ->

  if builder is undefined
    builder = moduleName
    moduleName = genLambdaName()
    lambdaModule = true

  info = new ModuleInfo
  builder info

  newModule = class extends BaseModule

  newModule.NAME = moduleName
  newModule.LAMBDA = !!lambdaModule
  newModule.DEFAULT_SETTINGS = info._defaultSettings
  newModule.EVENTS = info._events
  newModule.MODULE_EVENTS = info._moduleEvents
  newModule.GLOBAL_EVENTS = info._globalEvents
  newModule.ROOT_SELECTOR = info._rootSelector
  newModule.ELEMENTS = info._elements
  newModule.EXPECTED_SETTINGS = info._expectedSettings
  newModule.INIT = info._init

  for name, element of newModule.ELEMENTS
    if element.dynamic
      do (name, element) ->
        newModule::[name] = ->
          @find element.selector
    else
      newModule::[name] = $()

  $.extend newModule.prototype, info._methods

  __modules[moduleName] = newModule

  unless lambdaModule
    parts = moduleName.split '.'
    currentScope = window
    theName = parts.pop()
    for part in parts
      if currentScope[part] is undefined
        currentScope[part] = {}
      currentScope = currentScope[part]
    currentScope[theName] = newModule

  if newModule.INIT is LOAD
    $ ->
      modulesAPI.init newModule.NAME

  if newModule.INIT is LAZY
    newModule._bind()

  return newModule
  
modulesAPI = 

  find: (moduleName) ->
    __moduleInstances[moduleName] or []

  on: (eventName, moduleName, callback) ->
    __moduleEvents.bindGlobal eventName, moduleName, callback

  off:  (eventName, moduleName, callback) ->
    __moduleEvents.unbindGlobal eventName, moduleName, callback

  init: (moduleName, Module = __modules[moduleName], context = document) ->
    if Module
      elements = $(Module.ROOT_SELECTOR, context)
        .add $(context).filter(Module.ROOT_SELECTOR)
      for el in elements
        if $(el).modules(moduleName).length is 0
          new Module($ el)

  initAll: (context = document) ->
    for moduleName, Module of __modules when Module.INIT is LOAD
      modulesAPI.init moduleName, Module, context

jqueryPlugins =
  modules: (moduleName) ->
    _.compact($(el).module(moduleName) for el in @)
  module: (moduleName) ->
    instance = @first().data(moduleName)
    unless instance
      ModuleClass = __modules[moduleName]
      instance = new ModuleClass @first()
    instance

$(document).on HTML_INSERTED, (e) -> modulesAPI.initAll e.target

window.module = buildModule
window.modules = modulesAPI
jQuery::modules = jqueryPlugins.modules
jQuery::module = jqueryPlugins.module

