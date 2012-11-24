modules = {}
moduleInstances = {}

class window.BaseModule

  @NAME: 'BaseModule' 
  @EVENT_PREFIX: 'base-module'
  @DEFAULT_SETTINGS: {} 
  @ROOT_SELECTOR: null 

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
    # TODO

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
    "#{@EVENT_PREFIX}-#{name}"


class ModuleInfo

  @INIT_MODES: ['load', 'lazy', 'none']
  @DEFAULT_INIT: 'none'

  _methods: null
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

  methods: (newMethods) ->
    $.extend @_methods, newMethods

  init: (value) ->
    unless value in @constructor.INIT_MODES
      # FIXME: do it properly
      throw 'wrong value'
    @_init = value

  tree: (treeString) ->
    # TODO

  events: (eventsString) ->
    # TODO
    
  modulesEvents: (modulesEventsString) ->
    # TODO

  globalEvents: (globalEventsString) ->
    # TODO
  
  defaultSettings: (newDefaultSettings) ->
    $.extend @_defaultSettings, newDefaultSettings

  dependsOn: (moduleNames...) ->
    # TODO

  extends: (moduleName) ->
    # TODO

  eventPrefix: (prefix) ->
    @_eventPrefix = prefix

lastNameId = 0
genName = -> 
  "Anonimous#{lastNameId++}"

buildModule = (name, builder) ->

  if builder is undefined
    builder = name
    name = genName()

  info = new ModuleInfo name
  builder info

  newModule = class extends BaseModule

  newModule.NAME = name
  newModule.DEFAULT_SETTINGS = info._defaultSettings
  newModule.EVENT_PREFIX = info._eventPrefix or name

  for name, value of info._methods
    newModule::[name] = value

  #TODO: elements
  #TODO: events

  modules[name] = newModule

  unless /^Anonimous[0-9]+$/.test name
    # TODO: handle complex name
    window[name] = module

  return newModule
  
modulesAPI = 

  find: (moduleName) ->
    moduleInstances[moduleName] or []

  bind: (moduleName, eventName, callback) ->
    $(document).on modules[moduleName]._fixEventName(eventName), (e) ->
      moduleInstance = $(e.target).modules(moduleName)[0]
      callback moduleInstance if moduleInstance
      true

  initAll: (context) ->
    for name, Module in modules when Module.ROOT_SELECTOR != null
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

