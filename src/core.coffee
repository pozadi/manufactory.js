modules = {}
moduleInstances = {}

class BaseModule

  @NAME: 'BaseModule' 
  @EVENT_PREFIX: 'base-module'
  @DEFAULT_SETTINGS: {} 
  @ROOT_SELECTOR: null
  @ELEMENTS: {}
  @INIT: 'none'

  constructor: (@root, settings) ->
    @root.data @constructor.NAME, @
    @settings = $.extend {}, @constructor.DEFAULT_SETTINGS, settings
    @updateTree()
    @root.on 'html-inserted', => @updateTree()
    if moduleInstances[@constructor.NAME] is undefined
      moduleInstances[@constructor.NAME] = []
    moduleInstances[@constructor.NAME].push @
    @initializer?()

  updateTree: ->
    for name, element of @constructor.ELEMENTS when not element.dynamic
      @[name] = @find element.selector

  find: (args...) ->
    @root.find args...

  on: (eventName, args...) ->
    @root.on @constructor._fixEventName(eventName), args...

  off: (eventName, args...) ->
    @root.off @constructor._fixEventName(eventName), args...
  
  fire: (eventName, args...) ->
    @root.trigger @constructor._fixEventName(eventName), args...

  setOption: (name, value) ->
    @settings[name] = value

  @_fixEventName: (name) ->
    "#{@constructor.EVENT_PREFIX}-#{name}"


class ModuleInfo

  @INIT_MODES: ['load', 'lazy', 'none']
  @DEFAULT_INIT: 'none'

  _methods: null
  _rootSelector: null
  _elements: null
  _events: null
  _globalEvents: null
  _modulesEvents: null
  _init: null
  _defaultSettings: null
  _eventPrefix: null

  constructor: (@name) ->
    @_methods = {}
    @_elements = {}
    @_events = {}
    @_globalEvents = {}
    @_modulesEvents = {}
    @_init = @constructor.DEFAULT_INIT
    @_defaultSettings = {}

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
    result = (for word in selector.split(/[^a-z0-9]+/i)
      word.charAt(0).toUpperCase() + word.slice(1)).join ''
    result.charAt(0).toLowerCase() + result.slice(1)

  # Add element module interact with
  element: (selector, name=null, dynamic=false) ->
    if name is null
      name = @constructor.selectorToName selector
    @_elements[name] = {selector, dynamic}

  # Set root selector and all elements at once
  tree: (treeString) ->
    lines = ($.trim(line) for line in treeString.split('\n'))
    lines = (line for line in lines when line != '')
    @root lines.shift()
    for line in lines
      [selector, options] = line.split('/')
      [selector, options] = [$.trim(selector), $.trim(options)]
      if options != ''
        [name, options...] = options.split /\s+/
        name = $.trim(name)
        options = ($.trim(o) for o in options)
      else
        name = null
        options = []
      @element selector, name, 'dynamic' in options

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    # TODO
    
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
  "Anonimous#{lastNameId++}"

buildModule = (moduleName, builder) ->

  if builder is undefined
    builder = moduleName
    moduleName = genName()
    lambdaModule = true

  info = new ModuleInfo moduleName
  builder info

  newModule = class extends BaseModule

  newModule.NAME = moduleName
  newModule.DEFAULT_SETTINGS = info._defaultSettings
  newModule.EVENT_PREFIX = info._eventPrefix or moduleName
  newModule.ROOT_SELECTOR = info._rootSelector
  newModule.ELEMENTS = info._elements

  for name, value of info._methods
    newModule::[name] = value

  for name, element of newModule.ELEMENTS
    if element.dynamic
      do (name, element) ->
        newModule::[name] = ->
          @find element.selector
    else
      newModule::[name] = $()

  #TODO: events

  modules[moduleName] = newModule

  unless lambdaModule
    # TODO: handle complex name
    window[moduleName] = module

  return newModule
  
modulesAPI = 

  find: (moduleName) ->
    moduleInstances[moduleName] or []

  on: (moduleName, eventName, callback) ->
    $(document).on modules[moduleName]._fixEventName(eventName), (e) ->
      moduleInstance = $(e.target).modules(moduleName)[0]
      callback moduleInstance if moduleInstance
      true

  initAll: (context) ->
    for name, Module in modules when Module.ROOT_SELECTOR != null and Module.INIT is 'load'
      for el in $ Module.ROOT_SELECTOR, context
        $el = $ el
        # FIXME: dirty settings
        settings = $el.data()
        new Module $el, settings


jqueryPlugin = (moduleName) ->
  $(el).data(moduleName) for el in @

$ -> modulesAPI.initAll document
$(document).on 'html-inserted', (e) -> modulesAPI.initAll e.target

window.module = buildModule
window.modules = modulesAPI
jQuery::modules = jqueryPlugin

