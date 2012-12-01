// Generated by CoffeeScript 1.4.0
(function() {
  var BaseModule, DYNAMIC, HTML_INSERTED, LAMBDA_MODULE, LAZY, LOAD, ModuleInfo, NONE, action, buildModule, genName, jqueryPlugins, lastNameId, modulesAPI, __moduleInstances, __modules,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  __modules = {};

  __moduleInstances = {};

  LAZY = 'lazy';

  LOAD = 'load';

  NONE = 'none';

  DYNAMIC = 'dynamic';

  HTML_INSERTED = 'html-inserted';

  LAMBDA_MODULE = 'LambdaModule';

  BaseModule = (function() {

    function BaseModule(root, settings) {
      var data, option, _i, _len, _ref,
        _this = this;
      this.root = root;
      this.settings = $.extend({}, this.constructor.DEFAULT_SETTINGS);
      data = this.root.data();
      _ref = this.constructor.EXPECTED_SETTINGS;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        option = _ref[_i];
        if (data[option] !== void 0) {
          this.settings[option] = data[option];
        }
      }
      $.extend(this.settings, settings);
      this.root.data(this.constructor.NAME, this);
      if (this.constructor.INIT !== LAZY) {
        this._bind();
      }
      this.updateTree();
      this.root.on(HTML_INSERTED, function() {
        return _this.updateTree();
      });
      if (__moduleInstances[this.constructor.NAME] === void 0) {
        __moduleInstances[this.constructor.NAME] = [];
      }
      __moduleInstances[this.constructor.NAME].push(this);
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
          _results.push(this[name] = this.find(element.selector));
        }
      }
      return _results;
    };

    BaseModule.prototype._fixHandler = function(handler) {
      if (typeof handler === 'string') {
        handler = this[handler];
      }
      return _.bind(handler, this);
    };

    BaseModule.prototype._fixHandler2 = function(handler) {
      handler = this._fixHandler(handler);
      return function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        args.unshift(this);
        return handler.apply(null, args);
      };
    };

    BaseModule._fixHandler2 = function(handler) {
      var moduleClass;
      moduleClass = this;
      return function() {
        var args, moduleInstance, rootElement;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        rootElement = $(this).parents(moduleClass.ROOT_SELECTOR);
        moduleInstance = rootElement.module(moduleClass.NAME);
        handler = moduleInstance._fixHandler2(handler);
        return handler.apply(this, args);
      };
    };

    BaseModule._fixHandler2alt = function(handler) {
      var moduleClass;
      moduleClass = this;
      return function() {
        var args, moduleInstance, rootElement, _handler, _i, _len, _ref, _results;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref = $(moduleClass.ROOT_SELECTOR);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rootElement = _ref[_i];
          moduleInstance = $(rootElement).module(moduleClass.NAME);
          _handler = moduleInstance._fixHandler2(handler);
          _results.push(_handler.apply(this, args));
        }
        return _results;
      };
    };

    BaseModule._nameToSelector = function(name) {
      return this.ELEMENTS[name].selector;
    };

    BaseModule.prototype._bind = function() {
      var elementName, eventMeta, eventName, handler, selector, _i, _j, _len, _len1, _ref, _ref1, _results;
      _ref = this.constructor.EVENTS;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        eventMeta = _ref[_i];
        handler = eventMeta.handler, eventName = eventMeta.eventName, elementName = eventMeta.elementName;
        selector = this.constructor._nameToSelector(elementName);
        this.root.on(eventName, selector, this._fixHandler2(handler));
      }
      _ref1 = this.constructor.GLOBAL_EVENTS;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        eventMeta = _ref1[_j];
        eventName = eventMeta.eventName, selector = eventMeta.selector, handler = eventMeta.handler;
        _results.push($(document).on(eventName, selector, this._fixHandler2(handler)));
      }
      return _results;
    };

    BaseModule._bind = function() {
      var elementName, eventMeta, eventName, handler, selector, _fn, _i, _j, _len, _len1, _ref, _ref1, _results,
        _this = this;
      _ref = this.EVENTS;
      _fn = function(eventName, selector, handler) {
        return $(document).on(eventName, selector, _this._fixHandler2(handler));
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        eventMeta = _ref[_i];
        handler = eventMeta.handler, eventName = eventMeta.eventName, elementName = eventMeta.elementName;
        selector = this._nameToSelector(elementName);
        selector = "" + this.ROOT_SELECTOR + " " + selector;
        _fn(eventName, selector, handler);
      }
      _ref1 = this.GLOBAL_EVENTS;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        eventMeta = _ref1[_j];
        eventName = eventMeta.eventName, selector = eventMeta.selector, handler = eventMeta.handler;
        _results.push($(document).on(eventName, selector, this._fixHandler2alt(handler)));
      }
      return _results;
    };

    BaseModule.prototype.find = function() {
      var args, _ref;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref = this.root).find.apply(_ref, args);
    };

    BaseModule.prototype.on = function() {
      var args, eventName, _ref;
      eventName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.root).on.apply(_ref, [this.constructor.fixEventName(eventName)].concat(__slice.call(args)));
    };

    BaseModule.prototype.off = function() {
      var args, eventName, _ref;
      eventName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.root).off.apply(_ref, [this.constructor.fixEventName(eventName)].concat(__slice.call(args)));
    };

    BaseModule.prototype.fire = function() {
      var args, eventName, _ref;
      eventName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.root).trigger.apply(_ref, [this.constructor.fixEventName(eventName)].concat(__slice.call(args)));
    };

    BaseModule.prototype.setOption = function(name, value) {
      return this.settings[name] = value;
    };

    BaseModule.fixEventName = function(name) {
      return "" + this.constructor.EVENT_PREFIX + "-" + name;
    };

    return BaseModule;

  })();

  ModuleInfo = (function() {

    function ModuleInfo(_name) {
      this._name = _name;
      this._methods = {};
      this._elements = {};
      this._events = [];
      this._globalEvents = [];
      this._modulesEvents = {};
      this._defaultSettings = {};
      this._expectedSettings = [];
      this._init = 'none';
    }

    ModuleInfo.prototype.methods = function(newMethods) {
      return $.extend(this._methods, newMethods);
    };

    ModuleInfo.prototype.init = function(value) {
      return this._init = value;
    };

    ModuleInfo.prototype.root = function(rootSelector) {
      return this._rootSelector = rootSelector;
    };

    ModuleInfo.selectorToName = function(selector) {
      var first, word;
      first = true;
      return ((function() {
        var _i, _len, _ref, _results;
        _ref = selector.split(/[^a-z0-9]+/i);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          word = _ref[_i];
          if (word !== '') {
            if (first) {
              first = false;
              _results.push(word);
            } else {
              _results.push(word.charAt(0).toUpperCase() + word.slice(1));
            }
          }
        }
        return _results;
      })()).join('');
    };

    ModuleInfo.prototype.element = function(selector, name, dynamic) {
      if (name == null) {
        name = null;
      }
      if (dynamic == null) {
        dynamic = false;
      }
      if (name === null) {
        name = this.constructor.selectorToName(selector);
      }
      return this._elements[name] = {
        selector: selector,
        dynamic: dynamic
      };
    };

    ModuleInfo.prototype.tree = function(treeString) {
      var line, lines, name, options, selector, _i, _len, _ref, _ref1, _results;
      lines = _(treeString.split('\n')).map($.trim).filter(function(l) {
        return l !== '';
      });
      this.root(lines.shift());
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _ref = _.map(line.split('/'), $.trim), selector = _ref[0], options = _ref[1];
        if (options) {
          _ref1 = options.split(/\s+/), name = _ref1[0], options = 2 <= _ref1.length ? __slice.call(_ref1, 1) : [];
          name = $.trim(name);
          options = _.map(options, $.trim);
        } else {
          name = null;
          options = [];
        }
        _results.push(this.element(selector, name, __indexOf.call(options, DYNAMIC) >= 0));
      }
      return _results;
    };

    ModuleInfo.prototype.event = function(eventName, elementName, handler) {
      return this._events.push({
        elementName: elementName,
        eventName: eventName,
        handler: handler
      });
    };

    ModuleInfo.prototype.events = function(eventsString) {
      var elementName, eventName, handlerName, line, lines, _i, _len, _ref, _results;
      lines = _(eventsString.split('\n')).map($.trim).filter(function(l) {
        return l !== '';
      });
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _ref = _(line.split(/\s+/)).map($.trim), eventName = _ref[0], elementName = _ref[1], handlerName = _ref[2];
        _results.push(this.event(eventName, elementName, handlerName));
      }
      return _results;
    };

    ModuleInfo.prototype.modulesEvents = function(modulesEventsString) {};

    ModuleInfo.prototype.globalEvent = function(eventName, selector, handler) {
      return this._globalEvents.push({
        eventName: eventName,
        selector: selector,
        handler: handler
      });
    };

    ModuleInfo.prototype.globalEvents = function(globalEventsString) {};

    ModuleInfo.prototype.defaultSettings = function(newDefaultSettings) {
      return $.extend(this._defaultSettings, newDefaultSettings);
    };

    ModuleInfo.prototype.expectSettings = function() {
      var expectedSettings;
      expectedSettings = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._expectedSettings = _.union(this._expectedSettings, _.flatten(expectedSettings));
    };

    ModuleInfo.prototype.dependsOn = function() {
      var moduleNames;
      moduleNames = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    };

    ModuleInfo.prototype["extends"] = function(moduleName) {};

    ModuleInfo.prototype.eventPrefix = function(prefix) {
      return this._eventPrefix = prefix;
    };

    return ModuleInfo;

  })();

  lastNameId = 0;

  genName = function() {
    return "" + LAMBDA_MODULE + (lastNameId++);
  };

  buildModule = function(moduleName, builder) {
    var currentScope, element, info, lambdaModule, name, newModule, part, parts, theName, value, _i, _len, _ref, _ref1;
    if (builder === void 0) {
      builder = moduleName;
      moduleName = genName();
      lambdaModule = true;
    }
    info = new ModuleInfo(moduleName);
    builder(info);
    newModule = (function(_super) {

      __extends(_Class, _super);

      function _Class() {
        return _Class.__super__.constructor.apply(this, arguments);
      }

      return _Class;

    })(BaseModule);
    newModule.NAME = moduleName;
    newModule.LAMBDA = !!lambdaModule;
    newModule.DEFAULT_SETTINGS = info._defaultSettings;
    newModule.EVENT_PREFIX = info._eventPrefix || moduleName;
    newModule.EVENTS = info._events;
    newModule.GLOBAL_EVENTS = info._globalEvents;
    newModule.ROOT_SELECTOR = info._rootSelector;
    newModule.ELEMENTS = info._elements;
    newModule.EXPECTED_SETTINGS = info._expectedSettings;
    newModule.INIT = info._init;
    _ref = info._methods;
    for (name in _ref) {
      value = _ref[name];
      newModule.prototype[name] = value;
    }
    _ref1 = newModule.ELEMENTS;
    for (name in _ref1) {
      element = _ref1[name];
      if (element.dynamic) {
        (function(name, element) {
          return newModule.prototype[name] = function() {
            return this.find(element.selector);
          };
        })(name, element);
      } else {
        newModule.prototype[name] = $();
      }
    }
    __modules[moduleName] = newModule;
    if (!lambdaModule) {
      parts = moduleName.split('.');
      currentScope = window;
      theName = parts.pop();
      for (_i = 0, _len = parts.length; _i < _len; _i++) {
        part = parts[_i];
        if (currentScope[part] === void 0) {
          currentScope[part] = {};
        }
        currentScope = currentScope[part];
      }
      currentScope[theName] = newModule;
    }
    if (newModule.INIT === LOAD) {
      $(function() {
        return modulesAPI.init(newModule.NAME);
      });
    }
    if (newModule.INIT === LAZY) {
      newModule._bind();
    }
    return newModule;
  };

  modulesAPI = {
    find: function(moduleName) {
      return __moduleInstances[moduleName] || [];
    },
    on: function(moduleName, eventName, callback) {
      return $(document).on(__modules[moduleName].fixEventName(eventName), function(e) {
        var moduleInstance;
        moduleInstance = $(e.target).modules(moduleName)[0];
        if (moduleInstance) {
          callback(moduleInstance);
        }
        return true;
      });
    },
    init: function(moduleName, Module, context) {
      var el, elements, _i, _len, _results;
      if (Module == null) {
        Module = __modules[moduleName];
      }
      if (context == null) {
        context = document;
      }
      if (Module) {
        elements = $(Module.ROOT_SELECTOR, context).add($(context).filter(Module.ROOT_SELECTOR));
        _results = [];
        for (_i = 0, _len = elements.length; _i < _len; _i++) {
          el = elements[_i];
          if ($(el).modules(moduleName).length === 0) {
            _results.push(new Module($(el)));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }
    },
    initAll: function(context) {
      var Module, moduleName, _results;
      if (context == null) {
        context = document;
      }
      _results = [];
      for (moduleName in __modules) {
        Module = __modules[moduleName];
        if (Module.INIT === LOAD) {
          _results.push(modulesAPI.init(moduleName, Module, context));
        }
      }
      return _results;
    }
  };

  jqueryPlugins = {
    modules: function(moduleName) {
      var el;
      return _.compact((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = this.length; _i < _len; _i++) {
          el = this[_i];
          _results.push($(el).module(moduleName));
        }
        return _results;
      }).call(this));
    },
    module: function(moduleName) {
      var ModuleClass, instance;
      instance = this.first().data(moduleName);
      if (!instance) {
        ModuleClass = __modules[moduleName];
        if (ModuleClass.INIT === LAZY) {
          instance = new ModuleClass(this.first());
        }
      }
      return instance;
    }
  };

  $(document).on(HTML_INSERTED, function(e) {
    return modulesAPI.initAll(e.target);
  });

  window.module = buildModule;

  window.modules = modulesAPI;

  jQuery.prototype.modules = jqueryPlugins.modules;

  jQuery.prototype.module = jqueryPlugins.module;

  jQuery.prototype.htmlInserted = function() {
    return this.trigger('html-inserted');
  };

  action = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return $(function() {
      var a, callback;
      callback = args.pop();
      if (action.matcher((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = args.length; _i < _len; _i++) {
          a = args[_i];
          _results.push(a.split('#'));
        }
        return _results;
      })())) {
        return callback();
      }
    });
  };

  action.matcher = function(actions) {
    var a, selector;
    selector = ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = actions.length; _i < _len; _i++) {
        a = actions[_i];
        _results.push("body.controller-" + a[0] + ".action-" + a[1]);
      }
      return _results;
    })()).join(', ');
    return $(selector).length > 0;
  };

  window.action = action;

}).call(this);
