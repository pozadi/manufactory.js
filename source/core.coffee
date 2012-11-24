modules = {}
moduleInstances = {}

class BaseModule

  NAME: 'BaseModule' # should be redefined
  DEFAULT_SETTINGS: {} # should be redefined

  constructor: (@root, settings) ->
    @settings = $.extend {}, @DEFAULT_SETTINGS, settings
    @updateTree()
    @initializer?()

  updateTree: ->
    # TODO

  find: (args...) ->
    @root.find args...

  on: (eventName, args...) ->
    @root.on @_fixEventName(eventName), args...

  off: (eventName, args...) ->
    @root.off @_fixEventName(eventName), args...
  
  fire: (eventName, args...) ->
    @root.trigger @_fixEventName(eventName), args...

  setOption: (name, value) ->
    @settings[name] = value

  _fixEventName: (name) ->
    "#{@NAME}-#{name}"


class ModuleInfo

  INIT_MODES: ['load', 'lazy', 'none']
  DEFAULT_OPTIONS: {
    init: 'none'
  }

  _methods: null
  _elements: null
  _events: null
  _globalEvents: null
  _modulesEvents: null
  _options: null
  _defaultSettings: null

  constructor: (@name) ->
    @_methods = {}
    @_elements = {}
    @_events = {}
    @_globalEvents = {}
    @_modulesEvents = {}
    @_options = $.extend {}, @DEFAULT_OPTIONS
    @_defaultSettings = {}

  methods: (newMethods) ->
    $.extend @_methods, newMethods

  init: (value) ->
    unless value in @INIT_MODES
      # FIXME: do it properly
      throw 'wrong value'
    @_options.init = value

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
    # TODO


buildModule = (name, builder) ->

  if builder is undefined
    builder = name
    name = undefined

  info = new ModuleInfo name
  builder info

  newModule = class extends BaseModule

  newModule::NAME = name
  newModule::DEFAULT_SETTINGS = info._defaultSettings

  for name, value of info._methods
    newModule::[name] = value

  
modulesAPI = 

  find: (moduleName) ->
    #TODO

  bind: (moduleName, eventName, callback) ->
    # TODO

  initAll: (root) ->
    # TODO

jqueryPlugin = (moduleName) ->
  # TODO

window.module = buildModule
window.modules = modulesAPI
jQuery::modules = jqueryPlugin