window.manufactory =
  _modules: {}
  _instances: {}
  find: (moduleName) ->
    @_instances[moduleName] or []
  on: (eventName, moduleName, callback) ->
    @_events.globalCallbacks(moduleName, eventName).add(callback)
  off: (eventName, moduleName, callback) ->
    @_events.globalCallbacks(moduleName, eventName).remove(callback)
  init: (moduleName, context = document) ->
    selector = @_modules[moduleName].ROOT_SELECTOR
    if selector
      for el in $(selector, context).add $(context).filter selector
        new @_modules[moduleName] $ el
  initAll: (context = document) ->
    for moduleName, Module of @_modules when Module.AUTO_INIT
      @init moduleName, context
  _events:
    _globalHandlers: {}
    trigger: (moduleInstance, eventName, data) ->
      for callbacks in [
        @localCallbacks(moduleInstance, eventName), 
        @globalCallbacks(moduleInstance.constructor.NAME, eventName)
      ]
        callbacks.fireWith moduleInstance, [data, eventName]
    localCallbacks: (moduleInstance, eventName) ->
      (moduleInstance.__eventHandlers or= {})[eventName] or= $.Callbacks()
    globalCallbacks: (moduleName, eventName) ->
      (@_globalHandlers[moduleName] or= {})[eventName] or= $.Callbacks()


manufactory.module = (moduleName, builder) ->

  # Call with one argument:
  #   manufactory.module ->
  #     ...
  if builder is undefined
    builder = moduleName
    moduleName = _.uniqueId 'LambdaModule'
    lambdaModule = true

  newModule = class extends manufactory.BaseModule

  newModule.NAME = moduleName
  newModule.LAMBDA = !!lambdaModule

  builder new manufactory.ModuleInfo newModule

  manufactory._modules[moduleName] = newModule

  if newModule.AUTO_INIT
    $ -> manufactory.init newModule.NAME

  unless lambdaModule
    parts = moduleName.split '.'
    theName = parts.pop()
    currentScope = window
    for part in parts
      currentScope = (currentScope[part] or= {})
    currentScope[theName] = newModule

  return newModule
