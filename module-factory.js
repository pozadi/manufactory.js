// Generated by CoffeeScript 1.4.0
(function() {
  var BaseModule, DYNAMIC, GLOBAL, LAMBDA_MODULE, ModuleInfo, NEW_HTML, __moduleEvents, __moduleInstances, __modules, _emptyJQuery, _genLambdaName, _notOption, _removeFromArray, _splitToLines, _whitespace,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  __modules = {};

  __moduleInstances = {};

  __moduleEvents = {
    _globalHandlers: {},
    trigger: function(moduleInstance, eventName, data) {
      var globalHandlers, handler, localHandlers, _i, _len, _ref, _ref1, _ref2, _results;
      globalHandlers = ((_ref = this._globalHandlers[moduleInstance.constructor.NAME]) != null ? _ref[eventName] : void 0) || [];
      localHandlers = ((_ref1 = moduleInstance._eventHandlers) != null ? _ref1[eventName] : void 0) || [];
      _ref2 = _.union(localHandlers, globalHandlers);
      _results = [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        handler = _ref2[_i];
        _results.push(handler.call(moduleInstance, data, eventName));
      }
      return _results;
    },
    bindGlobal: function(eventName, moduleName, handler) {
      var _base, _base1;
      return ((_base = ((_base1 = this._globalHandlers)[moduleName] || (_base1[moduleName] = {})))[eventName] || (_base[eventName] = [])).push(handler);
    },
    unbindGlobal: function(eventName, moduleName, handler) {
      var _ref;
      return _removeFromArray((_ref = this._globalHandlers[moduleName]) != null ? _ref[eventName] : void 0, handler);
    },
    bindLocal: function(moduleInstance, eventName, handler) {
      var _base;
      return ((_base = (moduleInstance._eventHandlers || (moduleInstance._eventHandlers = {})))[eventName] || (_base[eventName] = [])).push(handler);
    },
    unbindLocal: function(moduleInstance, eventName, handler) {
      var _ref;
      return _removeFromArray((_ref = moduleInstance._eventHandlers) != null ? _ref[eventName] : void 0, handler);
    }
  };

  DYNAMIC = 'dynamic';

  GLOBAL = 'global';

  NEW_HTML = 'new-html';

  LAMBDA_MODULE = 'LambdaModule';

  _emptyJQuery = $();

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

  _removeFromArray = function(array, item) {
    var index;
    if (array && item) {
      index = array.indexOf(item);
      if (index > -1) {
        return array.splice(index, 1);
      }
    }
  };

  BaseModule = (function() {

    function BaseModule(root, settings) {
      var DEFAULT_SETTINGS, EXPECTED_SETTINGS, NAME, dataSettings, existing, _ref,
        _this = this;
      this.root = root;
      _ref = this.constructor, EXPECTED_SETTINGS = _ref.EXPECTED_SETTINGS, DEFAULT_SETTINGS = _ref.DEFAULT_SETTINGS, NAME = _ref.NAME;
      if (existing = this.root.data(NAME)) {
        return existing;
      }
      dataSettings = _.pick(this.root.data(), EXPECTED_SETTINGS);
      this.settings = _.extend({}, DEFAULT_SETTINGS, dataSettings, settings);
      this.root.data(NAME, this);
      this._bind();
      this.updateTree();
      this.root.on(NEW_HTML, function() {
        return _this.updateTree();
      });
      (__moduleInstances[NAME] || (__moduleInstances[NAME] = [])).push(this);
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
      return __moduleEvents.bindLocal(this, eventName, handler);
    };

    BaseModule.prototype.off = function(eventName, handler) {
      return __moduleEvents.unbindLocal(this, eventName, handler);
    };

    BaseModule.prototype.fire = function(eventName, data) {
      return __moduleEvents.trigger(this, eventName, data);
    };

    BaseModule.prototype.setOption = function(name, value) {
      return this.settings[name] = value;
    };

    BaseModule.prototype._fixHandler = function(handler) {
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

    BaseModule.prototype._bind = function() {
      var ELEMENTS, EVENTS, MODULE_EVENTS, elementName, eventMeta, eventName, global, handler, moduleName, selector, _i, _j, _len, _len1, _ref, _ref1, _results;
      _ref = this.constructor, ELEMENTS = _ref.ELEMENTS, EVENTS = _ref.EVENTS, MODULE_EVENTS = _ref.MODULE_EVENTS;
      for (_i = 0, _len = EVENTS.length; _i < _len; _i++) {
        eventMeta = EVENTS[_i];
        handler = eventMeta.handler, eventName = eventMeta.eventName, elementName = eventMeta.elementName;
        _ref1 = ELEMENTS[elementName], selector = _ref1.selector, global = _ref1.global;
        (global ? $(document) : this.root).on(eventName, selector, this._fixHandler(handler));
      }
      _results = [];
      for (_j = 0, _len1 = MODULE_EVENTS.length; _j < _len1; _j++) {
        eventMeta = MODULE_EVENTS[_j];
        eventName = eventMeta.eventName, moduleName = eventMeta.moduleName, handler = eventMeta.handler;
        _results.push(__moduleEvents.bindGlobal(eventName, moduleName, this._fixHandler(handler)));
      }
      return _results;
    };

    return BaseModule;

  })();

  ModuleInfo = (function() {

    function ModuleInfo() {
      this._methods = {};
      this._elements = {};
      this._events = [];
      this._moduleEvents = [];
      this._defaultSettings = {};
      this._expectedSettings = [];
      this._autoInit = true;
    }

    ModuleInfo.prototype.methods = function(newMethods) {
      return _.extend(this._methods, newMethods);
    };

    ModuleInfo.prototype.autoInit = function(value) {
      return this._autoInit = value;
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
          if (!(word !== '')) {
            continue;
          }
          word = word.toLowerCase();
          if (first) {
            first = false;
            _results.push(word);
          } else {
            _results.push(word.charAt(0).toUpperCase() + word.slice(1));
          }
        }
        return _results;
      })()).join('');
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
        name = this.constructor.selectorToName(selector);
      }
      return this._elements[name] = {
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
      return this._events.push({
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
      return this._moduleEvents.push({
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
      return _.extend(this._defaultSettings, newDefaultSettings);
    };

    ModuleInfo.prototype.expectSettings = function() {
      var expectedSettings;
      expectedSettings = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._expectedSettings = _.union(this._expectedSettings, _.flatten(expectedSettings));
    };

    return ModuleInfo;

  })();

  window.module = function(moduleName, builder) {
    var currentScope, element, info, lambdaModule, name, newModule, part, parts, theName, _i, _len, _ref;
    if (builder === void 0) {
      builder = moduleName;
      moduleName = _genLambdaName();
      lambdaModule = true;
    }
    info = new ModuleInfo;
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
    newModule.EVENTS = info._events;
    newModule.MODULE_EVENTS = info._moduleEvents;
    newModule.ROOT_SELECTOR = info._rootSelector;
    newModule.ELEMENTS = info._elements;
    newModule.EXPECTED_SETTINGS = info._expectedSettings;
    newModule.AUTO_INIT = info._autoInit;
    _ref = newModule.ELEMENTS;
    for (name in _ref) {
      element = _ref[name];
      if (element.dynamic) {
        (function(element) {
          return newModule.prototype[name] = function() {
            return $(element.selector, (element.global ? document : this.root));
          };
        })(element);
      } else {
        newModule.prototype[name] = _emptyJQuery;
      }
    }
    _.extend(newModule.prototype, info._methods);
    __modules[moduleName] = newModule;
    if (newModule.AUTO_INIT) {
      $(function() {
        return window.modules.init(newModule.NAME);
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

  window.modules = {
    find: function(moduleName) {
      return __moduleInstances[moduleName] || [];
    },
    on: function(eventName, moduleName, callback) {
      return __moduleEvents.bindGlobal(eventName, moduleName, callback);
    },
    off: function(eventName, moduleName, callback) {
      return __moduleEvents.unbindGlobal(eventName, moduleName, callback);
    },
    init: function(moduleName, context) {
      var el, selector, _i, _len, _ref, _results;
      if (context == null) {
        context = document;
      }
      selector = __modules[moduleName].ROOT_SELECTOR;
      if (selector) {
        _ref = $(selector, context).add($(context).filter(selector));
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          el = _ref[_i];
          _results.push(new __modules[moduleName]($(el)));
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
        if (Module.AUTO_INIT) {
          _results.push(this.init(moduleName, context));
        }
      }
      return _results;
    }
  };

  _.extend(jQuery.prototype, {
    module: function(moduleName) {
      if (this.length) {
        return new __modules[moduleName](this.first());
      }
    },
    newHtml: function() {
      return this.trigger(NEW_HTML);
    }
  });

  window.action = function() {
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

  window.action.matcher = function(actions) {
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

  $(document).on(NEW_HTML, function(e) {
    return window.modules.initAll(e.target);
  });

}).call(this);
