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
NEW_HTML = 'new-html'
NEW_HTML_FEW = 'new-html-few'
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
    @root.newHtml true, => @updateTree()
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

  constructor: ->
    @_methods = {}
    @_elements = {}
    @_events = []
    @_moduleEvents = []
    @_defaultSettings = {}
    @_expectedSettings = []
    @_autoInit = true

  # Set all module events
  methods: (newMethods) ->
    _.extend @_methods, newMethods

  autoInit: (value) ->
    @_autoInit = value

  # Set root selector
  root: (rootSelector) ->
    @_rootSelector = rootSelector

  # `div` → `div`  
  # `@button` → `button`
  # `.button` → `button`
  # `@button a` → `buttonA`
  # `@my-button` → `myButton`
  # `input[type=text]` → `inputTypeText`
  # `.js-something` → `something`
  #
  # Split to words (delimetr is all not letters and not digits characters) 
  # then join words in mixedCase notation.
  @selectorToName: (selector) ->
    result = _.map selector.split(/[^a-z0-9]+/i), (word) ->
      word = word.toLowerCase()
      word.charAt(0).toUpperCase() + word.slice(1)
    result = result.join ''
    result = result.replace /^Js/, ''
    result.charAt(0).toLowerCase() + result.slice(1)


  # Add element module interact with
  element: (selector, name=null, dynamic=false, global=false) ->
    if name is null
      name = @constructor.selectorToName selector
    @_elements[name] = {selector, dynamic, global}

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
    @_events.push {elementName, eventName, handler}

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    lines = _splitToLines eventsString
    for line in lines
      [eventName, elementName, handlerName] = line.split _whitespace
      @event eventName, elementName, handlerName
    
  moduleEvent: (eventName, moduleName, handler) ->
    @_moduleEvents.push {eventName, moduleName, handler}

  # Set all modules events module wants to handle 
  moduleEvents: (moduleEventsString) ->
    lines = _splitToLines moduleEventsString
    for line in lines
      [eventName, moduleName, handlerName] = line.split _whitespace
      @moduleEvent eventName, moduleName, handlerName
  
  # Set default module settings
  defaultSettings: (newDefaultSettings) ->
    _.extend @_defaultSettings, newDefaultSettings

  expectSettings: (expectedSettings...) ->
    @_expectedSettings = _.union @_expectedSettings, _.flatten expectedSettings


window.module = (moduleName, builder) ->

  if builder is undefined
    builder = moduleName
    moduleName = _genLambdaName()
    lambdaModule = true

  info = new ModuleInfo
  builder info

  newModule = class extends BaseModule

  newModule.NAME              = moduleName
  newModule.LAMBDA            = !!lambdaModule
  newModule.DEFAULT_SETTINGS  = info._defaultSettings
  newModule.EVENTS            = info._events
  newModule.MODULE_EVENTS     = info._moduleEvents
  newModule.ROOT_SELECTOR     = info._rootSelector
  newModule.ELEMENTS          = info._elements
  newModule.EXPECTED_SETTINGS = info._expectedSettings
  newModule.AUTO_INIT         = info._autoInit

  for name, element of newModule.ELEMENTS when element.dynamic
    do (element) ->
      newModule::[name] = ->
        $ element.selector, (if element.global then document else @root)

  _.extend newModule::, info._methods

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
  newHtml: (few=false, callback=null) ->
    if typeof few is 'function'
      callback = few
      few = false
    if typeof callback is 'function'
      @on NEW_HTML, callback
      if few
        @on NEW_HTML_FEW, callback
    else
      @trigger(if few then NEW_HTML_FEW else NEW_HTML)
}


# Run some JavaScript only on particular action and/or controller.
#   action 'controller_name#action_name', -> ...
#   action 'foo#bar', 'foo#baz', -> ...
#   action 'foo#', '#baz', -> ...
_action = (args...) ->
  $ ->
    currentA = (_action.currentAction or= _action.getCurrentAction())
    currentC = (_action.currentController or= _action.getCurrentController())
    callback = args.pop()
    for c_a in args
      [c, a] = c_a.split('#')
      if (c is currentC or !c) and (a is currentA or !a)
        callback()
        break

_action.getCurrentAction = ->
  $('body').attr('class').match(/action-(\S+)/)?[1]

_action.getCurrentController = ->
  $('body').attr('class').match(/controller-(\S+)/)?[1]

window.action = _action


$(document).newHtml (e) -> window.modules.initAll e.target
