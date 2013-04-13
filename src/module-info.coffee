# Constants
GLOBAL = 'global'

# Utils
whitespace = /\s+/
splitToLines =  (str) -> _(str.split '\n').filter (i) -> i != ''
notOption = (i) -> i not in [GLOBAL]

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
    @Module.DEFAULT_SETTINGS = {}
    @Module.EXPECTED_SETTINGS = []
    @Module.AUTO_INIT = true

  # Set all module events
  methods: (newMethods) ->
    _.extend @Module::, newMethods
    @

  autoInit: (value) ->
    @Module.AUTO_INIT = value
    @

  # Set root selector
  root: (rootSelector) ->
    @Module.ROOT_SELECTOR = $.trim(rootSelector)
    @

  # Add element module interact with
  element: (selector, name=null, global=false) ->
    if name is null
      name = selectorToName selector
    @Module.ELEMENTS[name] = {selector, global}
    @

  # Set root selector and all elements at once
  tree: (treeString) ->
    lines = splitToLines treeString
    @root lines.shift()?.split('/')[0]
    for line in lines
      [selector, options] = _.map line.split('/'), $.trim
      options = (options or '').split whitespace
      name = _.filter(options, notOption)[0] or null
      if selector
        @element selector, name, GLOBAL in options
    @

  event: (eventName, elementName, handler) ->
    @Module.EVENTS.push {elementName, eventName, handler}
    @

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    lines = splitToLines eventsString
    for line in lines
      [eventName, elementName, handlerName] = line.split whitespace
      if not handlerName?
        handlerName = elementName
        elementName = 'root'
      @event eventName, elementName, handlerName
    @
    
  # Set default module settings
  defaultSettings: (newDefaultSettings) ->
    _.extend @Module.DEFAULT_SETTINGS, newDefaultSettings
    @

  expectSettings: (expectedSettings) ->
    @Module.EXPECTED_SETTINGS = 
      _.union @Module.EXPECTED_SETTINGS, expectedSettings.split whitespace
    @
