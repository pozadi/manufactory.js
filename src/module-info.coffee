class manufactory.ModuleInfo

  constructor: (@Module) ->

  # Set all module events
  methods: (newMethods) ->
    _.extend @Module::, newMethods
    @

  autoInit: (value) ->
    @Module.autoInit value
    @

  # Set root selector
  root: (rootSelector) ->
    @Module.root rootSelector
    @

  # Add element module interact with
  element: (selector, name=null, global=false) ->
    @Module.element selector, name, global
    @

  # Set root selector and all elements at once
  tree: (treeString) ->
    @Module.tree treeString
    @

  event: (eventName, elementName, handler) ->
    @Module.event eventName, elementName, handler
    @

  # Set all DOM events module wants to handle
  events: (eventsString) ->
    @Module.events eventsString
    @
    
  # Set default module settings
  defaultSettings: (newDefaultSettings) ->
    @Module.defaultSettings newDefaultSettings
    @

  expectSettings: (expectedSettings) ->
    @Module.expectSettings expectedSettings
    @
