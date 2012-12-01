__modules = {}
__moduleInstances = {}

class BaseModule

  @NAME: 'BaseModule' 
  @EVENT_PREFIX: 'base-module'
  @DEFAULT_SETTINGS: {} 
  @ROOT_SELECTOR: null
  @ELEMENTS: {}
  @INIT: 'none'
  @EXPECTED_SETTINGS: []

  constructor: (@root, settings) ->
    @settings = $.extend {}, @constructor.DEFAULT_SETTINGS
    data = @root.data()
    for option in @constructor.EXPECTED_SETTINGS
      if data[option] != undefined
        @settings[option] = data[option]
    $.extend @settings, settings
    @root.data @constructor.NAME, @
    @_bind() unless @constructor.INIT is 'lazy'
    @updateTree()
    @root.on 'html-inserted', => @updateTree()
    if __moduleInstances[@constructor.NAME] is undefined
      __moduleInstances[@constructor.NAME] = []
    __moduleInstances[@constructor.NAME].push @
    @initializer?()

  updateTree: ->
    for name, element of @constructor.ELEMENTS when not element.dynamic
      @[name] = @find element.selector

  _bind: ->
    moduleInstance = @
    for eventMeta in @constructor.EVENTS
      {handler, eventName, elementName} = eventMeta
      selector = @constructor.ELEMENTS[elementName].selector
      if typeof handler is 'string'
        handler = @[handler]
      do (eventName, selector, handler) =>
        @root.on eventName, selector, (args...) ->
          args.unshift @
          handler.apply moduleInstance, args

  @_bind: ->
    moduleClass = @
    for eventMeta in @EVENTS
      {handler, eventName, elementName} = eventMeta
      selector = @ELEMENTS[elementName].selector
      if typeof handler is 'string'
        handler = @::[handler]
      do (eventName, selector, handler) =>
        $(document).on eventName, "#{@ROOT_SELECTOR} #{selector}", (args...) ->
          rootElement = $(@).parents(moduleClass.ROOT_SELECTOR)
          moduleInstance = rootElement.module moduleClass.NAME
          args.unshift @
          handler.apply moduleInstance, args

  find: (args...) ->
    @root.find args...

  on: (eventName, args...) ->
    @root.on @constructor.fixEventName(eventName), args...

  off: (eventName, args...) ->
    @root.off @constructor.fixEventName(eventName), args...
  
  fire: (eventName, args...) ->
    @root.trigger @constructor.fixEventName(eventName), args...

  setOption: (name, value) ->
    @settings[name] = value

  @fixEventName: (name) ->
    "#{@constructor.EVENT_PREFIX}-#{name}"


class ModuleInfo

  constructor: (@_name) ->
    @_methods = {}
    @_elements = {}
    @_events = []
    @_globalEvents = {}
    @_modulesEvents = {}
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
      @element selector, name, 'dynamic' in options

  event: (eventName, elementName, handler) ->
    @_events.push {elementName, eventName, handler}

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    lines = _(eventsString.split '\n').map($.trim).filter (l) -> l != ''
    for line in lines
      [eventName, elementName, handlerName] = _(line.split /\s+/).map($.trim)
      @event eventName, elementName, handlerName
    
  # Set all modules events module wants to handle 
  modulesEvents: (modulesEventsString) ->
    # TODO

  # Set all global DOM events module wants to handle
  globalEvents: (globalEventsString) ->
    # TODO
  
  # Set default module settings
  defaultSettings: (newDefaultSettings) ->
    $.extend @_defaultSettings, newDefaultSettings

  expectSettings: (expectedSettings...) ->
    @_expectedSettings = _.union @_expectedSettings, _.flatten expectedSettings

  # 
  dependsOn: (moduleNames...) ->
    # TODO

  # 
  extends: (moduleName) ->
    # TODO

  # Set module event prefix
  # That prefix will added to module event name, when it will proxied
  # to DOM event
  eventPrefix: (prefix) ->
    @_eventPrefix = prefix

lastNameId = 0
genName = -> 
  "LambdaModule#{lastNameId++}"

buildModule = (moduleName, builder) ->

  if builder is undefined
    builder = moduleName
    moduleName = genName()
    lambdaModule = true

  info = new ModuleInfo moduleName
  builder info

  newModule = class extends BaseModule

  newModule.NAME = moduleName
  newModule.LAMBDA = !!lambdaModule
  newModule.DEFAULT_SETTINGS = info._defaultSettings
  newModule.EVENT_PREFIX = info._eventPrefix or moduleName
  newModule.EVENTS = info._events
  newModule.ROOT_SELECTOR = info._rootSelector
  newModule.ELEMENTS = info._elements
  newModule.EXPECTED_SETTINGS = info._expectedSettings
  newModule.INIT = info._init

  for name, value of info._methods
    newModule::[name] = value

  for name, element of newModule.ELEMENTS
    if element.dynamic
      do (name, element) ->
        newModule::[name] = ->
          @find element.selector
    else
      newModule::[name] = $()

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

  if newModule.INIT is 'load'
    $ ->
      modulesAPI.init newModule.NAME

  if newModule.INIT is 'lazy'
    newModule._bind()

  return newModule
  
modulesAPI = 

  find: (moduleName) ->
    __moduleInstances[moduleName] or []

  on: (moduleName, eventName, callback) ->
    $(document).on __modules[moduleName].fixEventName(eventName), (e) ->
      moduleInstance = $(e.target).modules(moduleName)[0]
      callback moduleInstance if moduleInstance
      true

  init: (moduleName, Module = __modules[moduleName], context = document) ->
    if Module
      elements = $(Module.ROOT_SELECTOR, context)
        .add $(context).filter(Module.ROOT_SELECTOR)
      for el in elements
        if $(el).modules(moduleName).length is 0
          new Module($ el)

  initAll: (context = document) ->
    for moduleName, Module of __modules when Module.INIT is 'load'
      modulesAPI.init moduleName, Module, context

jqueryPlugins =
  modules: (moduleName) ->
    _.compact( $(el).module(moduleName) for el in @ )
  module: (moduleName) ->
    instance = @first().data(moduleName)
    unless instance
      ModuleClass = __modules[moduleName]
      if ModuleClass.INIT == 'lazy'
        instance = new ModuleClass @first()
    instance

$(document).on 'html-inserted', (e) -> modulesAPI.initAll e.target

window.module = buildModule
window.modules = modulesAPI
jQuery::modules = jqueryPlugins.modules
jQuery::module = jqueryPlugins.module

