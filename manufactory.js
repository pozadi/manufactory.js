// Generated by CoffeeScript 1.4.0
(function() {
  var DYNAMIC, GLOBAL, LAMBDA_MODULE, manufactory, _genLambdaName, _notOption, _splitToLines, _whitespace,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DYNAMIC = 'dynamic';

  GLOBAL = 'global';

  LAMBDA_MODULE = 'LambdaModule';

  _whitespace = /\s+/;

  _splitToLines = function(str) {
    return _(str.split('\n')).filter(function(i) {
      return i !== '';
    });
  };

  _notOption = function(i) {
    return i !== DYNAMIC && i !== GLOBAL;
  };

  _genLambdaName = function() {
    return _.uniqueId(LAMBDA_MODULE);
  };

  manufactory = window.manufactory = {
    _modules: {},
    _instances: {},
    find: function(moduleName) {
      return this._instances[moduleName] || [];
    },
    on: function(eventName, moduleName, callback) {
      return this._events.bindGlobal(eventName, moduleName, callback);
    },
    off: function(eventName, moduleName, callback) {
      return this._events.unbindGlobal(eventName, moduleName, callback);
    },
    init: function(moduleName, context) {
      var el, selector, _i, _len, _ref, _results;
      if (context == null) {
        context = document;
      }
      selector = this._modules[moduleName].ROOT_SELECTOR;
      if (selector) {
        _ref = $(selector, context).add($(context).filter(selector));
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          el = _ref[_i];
          _results.push(new this._modules[moduleName]($(el)));
        }
        return _results;
      }
    },
    initAll: function(context) {
      var Module, moduleName, _ref, _results;
      if (context == null) {
        context = document;
      }
      _ref = this._modules;
      _results = [];
      for (moduleName in _ref) {
        Module = _ref[moduleName];
        if (Module.AUTO_INIT) {
          _results.push(this.init(moduleName, context));
        }
      }
      return _results;
    }
  };

  _.extend($.fn, {
    module: function(moduleName) {
      if (this.length) {
        return new manufactory._modules[moduleName](this.first());
      }
    }
  });

  manufactory.BaseModule = (function() {

    function BaseModule(root, settings) {
      var DEFAULT_SETTINGS, EXPECTED_SETTINGS, NAME, dataSettings, existing, _base, _ref;
      this.root = root;
      _ref = this.constructor, EXPECTED_SETTINGS = _ref.EXPECTED_SETTINGS, DEFAULT_SETTINGS = _ref.DEFAULT_SETTINGS, NAME = _ref.NAME;
      if (existing = this.root.data(NAME)) {
        return existing;
      }
      ((_base = manufactory._instances)[NAME] || (_base[NAME] = [])).push(this);
      this.root.data(NAME, this);
      dataSettings = _.pick(this.root.data(), EXPECTED_SETTINGS);
      this.settings = _.extend({}, DEFAULT_SETTINGS, dataSettings, settings);
      this["__bind"]();
      this.updateTree();
      if (typeof this.initializer === "function") {
        this.initializer();
      }
    }

    BaseModule.prototype.updateTree = function() {
      var element, name, _ref, _results;
      _ref = this.constructor.ELEMENTS;
      _results = [];
      for (name in _ref) {
        element = _ref[name];
        if (!element.dynamic) {
          _results.push(this[name] = $(element.selector, (element.global ? document : this.root)));
        }
      }
      return _results;
    };

    BaseModule.prototype.find = function() {
      var args, _ref;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref = this.root).find.apply(_ref, args);
    };

    BaseModule.prototype.on = function(eventName, handler) {
      return manufactory._events.bindLocal(this, eventName, handler);
    };

    BaseModule.prototype.off = function(eventName, handler) {
      return manufactory._events.unbindLocal(this, eventName, handler);
    };

    BaseModule.prototype.fire = function(eventName, data) {
      return manufactory._events.trigger(this, eventName, data);
    };

    BaseModule.prototype.setOption = function(name, value) {
      return this.settings[name] = value;
    };

    BaseModule.prototype.__fixHandler = function(handler) {
      if (typeof handler === 'string') {
        handler = this[handler];
      }
      handler = _.bind(handler, this);
      return function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        args.unshift(this);
        return handler.apply(null, args);
      };
    };

    BaseModule.prototype["__bind"] = function() {
      var ELEMENTS, EVENTS, MODULE_EVENTS, elementName, eventMeta, eventName, global, handler, moduleName, selector, _i, _j, _len, _len1, _ref, _ref1, _results;
      _ref = this.constructor, ELEMENTS = _ref.ELEMENTS, EVENTS = _ref.EVENTS, MODULE_EVENTS = _ref.MODULE_EVENTS;
      for (_i = 0, _len = EVENTS.length; _i < _len; _i++) {
        eventMeta = EVENTS[_i];
        handler = eventMeta.handler, eventName = eventMeta.eventName, elementName = eventMeta.elementName;
        _ref1 = ELEMENTS[elementName], selector = _ref1.selector, global = _ref1.global;
        (global ? $(document) : this.root).on(eventName, selector, this.__fixHandler(handler));
      }
      _results = [];
      for (_j = 0, _len1 = MODULE_EVENTS.length; _j < _len1; _j++) {
        eventMeta = MODULE_EVENTS[_j];
        eventName = eventMeta.eventName, moduleName = eventMeta.moduleName, handler = eventMeta.handler;
        _results.push(manufactory._events.bindGlobal(eventName, moduleName, this.__fixHandler(handler)));
      }
      return _results;
    };

    return BaseModule;

  })();

  manufactory.ModuleInfo = (function() {
    var selectorToName;

    selectorToName = function(selector) {
      return $.camelCase(selector.replace(/[^a-z0-9]+/ig, '-').replace(/^-/, '').replace(/-$/, '').replace(/^js-/, ''));
    };

    function ModuleInfo(Module) {
      this.Module = Module;
      this.Module.ELEMENTS = {};
      this.Module.EVENTS = [];
      this.Module.MODULE_EVENTS = [];
      this.Module.DEFAULT_SETTINGS = {};
      this.Module.EXPECTED_SETTINGS = [];
      this.Module.AUTO_INIT = true;
    }

    ModuleInfo.prototype.methods = function(newMethods) {
      return _.extend(this.Module.prototype, newMethods);
    };

    ModuleInfo.prototype.autoInit = function(value) {
      return this.Module.AUTO_INIT = value;
    };

    ModuleInfo.prototype.root = function(rootSelector) {
      return this.Module.ROOT_SELECTOR = rootSelector;
    };

    ModuleInfo.prototype.element = function(selector, name, dynamic, global) {
      if (name == null) {
        name = null;
      }
      if (dynamic == null) {
        dynamic = false;
      }
      if (global == null) {
        global = false;
      }
      if (name === null) {
        name = selectorToName(selector);
      }
      return this.Module.ELEMENTS[name] = {
        selector: selector,
        dynamic: dynamic,
        global: global
      };
    };

    ModuleInfo.prototype.tree = function(treeString) {
      var line, lines, name, options, selector, _i, _len, _ref, _results;
      lines = _splitToLines(treeString);
      this.root(lines.shift());
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _ref = _.map(line.split('/'), $.trim), selector = _ref[0], options = _ref[1];
        options = (options || '').split(_whitespace);
        name = _.filter(options, _notOption)[0] || null;
        _results.push(this.element(selector, name, __indexOf.call(options, DYNAMIC) >= 0, __indexOf.call(options, GLOBAL) >= 0));
      }
      return _results;
    };

    ModuleInfo.prototype.event = function(eventName, elementName, handler) {
      return this.Module.EVENTS.push({
        elementName: elementName,
        eventName: eventName,
        handler: handler
      });
    };

    ModuleInfo.prototype.events = function(eventsString) {
      var elementName, eventName, handlerName, line, lines, _i, _len, _ref, _results;
      lines = _splitToLines(eventsString);
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _ref = line.split(_whitespace), eventName = _ref[0], elementName = _ref[1], handlerName = _ref[2];
        _results.push(this.event(eventName, elementName, handlerName));
      }
      return _results;
    };

    ModuleInfo.prototype.moduleEvent = function(eventName, moduleName, handler) {
      return this.Module.MODULE_EVENTS.push({
        eventName: eventName,
        moduleName: moduleName,
        handler: handler
      });
    };

    ModuleInfo.prototype.moduleEvents = function(moduleEventsString) {
      var eventName, handlerName, line, lines, moduleName, _i, _len, _ref, _results;
      lines = _splitToLines(moduleEventsString);
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _ref = line.split(_whitespace), eventName = _ref[0], moduleName = _ref[1], handlerName = _ref[2];
        _results.push(this.moduleEvent(eventName, moduleName, handlerName));
      }
      return _results;
    };

    ModuleInfo.prototype.defaultSettings = function(newDefaultSettings) {
      return _.extend(this.Module.DEFAULT_SETTINGS, newDefaultSettings);
    };

    ModuleInfo.prototype.expectSettings = function() {
      var expectedSettings;
      expectedSettings = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.Module.EXPECTED_SETTINGS = _.union(this.Module.EXPECTED_SETTINGS, _.flatten(expectedSettings));
    };

    return ModuleInfo;

  })();

  manufactory.module = function(moduleName, builder) {
    var currentScope, element, lambdaModule, name, newModule, part, parts, theName, _i, _len, _ref;
    if (builder === void 0) {
      builder = moduleName;
      moduleName = _genLambdaName();
      lambdaModule = true;
    }
    newModule = (function(_super) {

      __extends(_Class, _super);

      function _Class() {
        return _Class.__super__.constructor.apply(this, arguments);
      }

      return _Class;

    })(manufactory.BaseModule);
    newModule.NAME = moduleName;
    newModule.LAMBDA = !!lambdaModule;
    builder(new manufactory.ModuleInfo(newModule));
    _ref = newModule.ELEMENTS;
    for (name in _ref) {
      element = _ref[name];
      if (element.dynamic) {
        (function(element) {
          return newModule.prototype[name] = function() {
            return $(element.selector, (element.global ? document : this.root));
          };
        })(element);
      }
    }
    manufactory._modules[moduleName] = newModule;
    if (newModule.AUTO_INIT) {
      $(function() {
        return manufactory.init(newModule.NAME);
      });
    }
    if (!lambdaModule) {
      parts = moduleName.split('.');
      theName = parts.pop();
      currentScope = window;
      for (_i = 0, _len = parts.length; _i < _len; _i++) {
        part = parts[_i];
        currentScope = (currentScope[part] || (currentScope[part] = {}));
      }
      currentScope[theName] = newModule;
    }
    return newModule;
  };

  manufactory._events = {
    _globalHandlers: {},
    trigger: function(moduleInstance, eventName, data) {
      var _ref, _ref1, _ref2, _ref3;
      if ((_ref = this._globalHandlers[moduleInstance.constructor.NAME]) != null) {
        if ((_ref1 = _ref[eventName]) != null) {
          _ref1.fireWith(moduleInstance, [data, eventName]);
        }
      }
      return (_ref2 = moduleInstance._eventHandlers) != null ? (_ref3 = _ref2[eventName]) != null ? _ref3.fireWith(moduleInstance, [data, eventName]) : void 0 : void 0;
    },
    bindGlobal: function(eventName, moduleName, handler) {
      var _base, _base1;
      return ((_base = ((_base1 = this._globalHandlers)[moduleName] || (_base1[moduleName] = {})))[eventName] || (_base[eventName] = $.Callbacks())).add(handler);
    },
    unbindGlobal: function(eventName, moduleName, handler) {
      var _ref, _ref1;
      return (_ref = this._globalHandlers[moduleName]) != null ? (_ref1 = _ref[eventName]) != null ? _ref1.remove(handler) : void 0 : void 0;
    },
    bindLocal: function(moduleInstance, eventName, handler) {
      var _base;
      return ((_base = (moduleInstance._eventHandlers || (moduleInstance._eventHandlers = {})))[eventName] || (_base[eventName] = $.Callbacks())).add(handler);
    },
    unbindLocal: function(moduleInstance, eventName, handler) {
      var _ref, _ref1;
      return (_ref = moduleInstance._eventHandlers) != null ? (_ref1 = _ref[eventName]) != null ? _ref1.remove(handler) : void 0 : void 0;
    }
  };

}).call(this);
