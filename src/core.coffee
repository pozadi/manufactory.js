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
    ((@_globalHandlers[moduleName] or= {})[eventName] or= []).push handler
  unbindGlobal: (eventName, moduleName, handler) ->
    _removeFromArray @_globalHandlers[moduleName]?[eventName], handler
  bindLocal: (moduleInstance, eventName, handler) ->
    ((moduleInstance._eventHandlers or= {})[eventName] or= []).push handler
  unbindLocal: (moduleInstance, eventName, handler) ->
    _removeFromArray moduleInstance._eventHandlers?[eventName], handler
}


DYNAMIC = 'dynamic'
GLOBAL = 'global'
HTML_INSERTED = 'html-inserted'
LAMBDA_MODULE = 'LambdaModule'


_emptyJQuery = $()
_whitespace = /\s+/
_splitToLines =  (str) -> _(str.split '\n').filter (i) -> i != ''
_notOption = (i) -> i not in [DYNAMIC, GLOBAL]
_genLambdaName = -> _.uniqueId LAMBDA_MODULE
_removeFromArray = (array, item) ->
  if array and item
    index = array.indexOf item
    if index > -1
      array.splice index, 1


class BaseModule

  constructor: (@root, settings) ->
    {EXPECTED_SETTINGS, DEFAULT_SETTINGS, NAME} = @constructor
    if existing = @root.data NAME
      return existing
    dataSettings = _.pick @root.data(), EXPECTED_SETTINGS
    @settings = _.extend {}, DEFAULT_SETTINGS, dataSettings, settings
    @root.data NAME, @
    @_bind()
    @updateTree()
    @root.on HTML_INSERTED, => @updateTree()
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

  _fixHandler: (handler) ->
    if typeof handler is 'string'
      handler = @[handler]
    handler = _.bind handler, @
    (args...) ->
      args.unshift @
      handler args...

  _bind: ->
    {ELEMENTS, EVENTS, MODULE_EVENTS} = @constructor
    for eventMeta in EVENTS
      {handler, eventName, elementName} = eventMeta
      {selector, global} = ELEMENTS[elementName]
      (if global
        $(document) 
      else
        @root).on eventName, selector, @_fixHandler handler
    for eventMeta in MODULE_EVENTS
      {eventName, moduleName, handler} = eventMeta
      __moduleEvents.bindGlobal eventName, moduleName, @_fixHandler handler


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
  #
  # Split to words (delimetr is all not letters and not digits characters) 
  # then join words in mixedCase notation.
  @selectorToName: (selector) ->
    first = true
    (for word in selector.split /[^a-z0-9]+/i when word != ''
      word = word.toLowerCase()
      if first
        first = false
        word
      else
        word.charAt(0).toUpperCase() + word.slice(1)
    ).join ''

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

  for name, element of newModule.ELEMENTS 
    if element.dynamic
      do (element) ->
        newModule::[name] = ->
          $ element.selector, (if element.global then document else @root)
    else
      newModule::[name] = _emptyJQuery

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


_.extend jQuery::, {
  module: (moduleName) ->
    if @length
      new __modules[moduleName] @first()
  htmlInserted: ->
    @trigger HTML_INSERTED
}


# Run some JavaScript only on particular action.
#   action 'controller_name#action_name', -> ...
#   action 'foo#bar', 'foo#baz', -> ...
window.action = (args...) ->
  $ ->
    callback = args.pop()
    callback() if action.matcher(a.split('#') for a in args)

# Check if some of listed actions handling now.
# You can redefine this function.
#   action.matcher [['controller_name', 'action_name'], [...], ...]
window.action.matcher = (actions) ->
  selector = (for a in actions
    # Suppose you add .controller-foo and .action-bar classes to body on server-side.
    "body.controller-#{a[0]}.action-#{a[1]}").join ', '
  $(selector).length > 0


$(document).on HTML_INSERTED, (e) -> window.modules.initAll e.target
