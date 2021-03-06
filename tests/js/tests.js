// Generated by CoffeeScript 1.4.0
(function() {

  qunitTap(QUnit, function(str) {
    return console.log(str);
  });

  $(function() {
    var baseDomEventsTest, baseInitTest, baseUpdateTest, hiddenDom, moduleACount, moduleAElementsTree, moduleAHtmlAll, moduleAHtmlOne;
    moduleAHtmlOne = "<div class=\"js-module\">\n  <button>hello</button>\n  <input type=\"button\" value=\"hello\">\n  <input type=\"text\" name=\"a\">\n  <input type=\"text\" name=\"b\">\n  <div class=\"js-some-div-\">\n    <div class=\"child\">abc</div>\n  </div>\n</div>";
    moduleAHtmlAll = "" + moduleAHtmlOne + "\n" + moduleAHtmlOne + "\n<div class=\"-global-div\">";
    hiddenDom = $('<div>').hide().appendTo('body');
    moduleACount = function() {
      return manufactory.find('test.modules.A').length;
    };
    moduleAElementsTree = ".js-module    / foo bar static    dynamic  global /\n\n  button, [type=button]/ allButtons !@#$%^&*()\_+±   \n  input[type=text] \n\n  / withEmptySelector\n\n  // comment\n  .js-some-div-  \n  .js-some-div- .child    // comment\n\n  .-global-div /global / Приве†\n* / all";
    QUnit.testStart(function(details) {
      $('<div>').html(moduleAHtmlAll).appendTo(hiddenDom);
      window.TestModuleA = manufactory.module('test.modules.A', function(M) {
        M.tree(moduleAElementsTree);
        M.expectSettings('foo bar');
        M.defaultSettings({
          foo: 'default foo',
          bar: 'default bar'
        });
        return M.methods({
          initializer: function() {
            return this.message = 'hello';
          },
          getMessage: function() {
            return this.message;
          }
        });
      });
      window.TestModuleB = manufactory.module(function(Module) {
        Module.root('.js-module').element('button, [type=button]', 'allButtons').element('input[type=text]').element('.js-some-div-').element('.js-some-div- .child').element('.-global-div', null, true).element('*', 'all');
        return Module.autoInit(false);
      });
      return window.TestModuleEmpty = manufactory.module(function(M) {});
    });
    QUnit.testDone(function(details) {
      window.TestModuleA = window.TestModuleB = window.TestModuleEmpty = void 0;
      window.test.modules = void 0;
      hiddenDom.empty();
      $(document).off();
      manufactory._instances = {};
      return manufactory._modules = {};
    });
    test("global varibles", function() {
      return equal(TestModuleA, window.test.modules.A);
    });
    test("automatic initialisation", function() {
      equal(moduleACount(), 2);
      equal(manufactory.find(TestModuleB.NAME).length, 0);
      return equal(manufactory.find(TestModuleEmpty.NAME).length, 0);
    });
    test("M.tree(), M.root(), M.element()", function() {
      equal(TestModuleA.ROOT_SELECTOR, '.js-module');
      equal(TestModuleEmpty.ROOT_SELECTOR, null);
      equal(TestModuleB.ROOT_SELECTOR, TestModuleA.ROOT_SELECTOR);
      deepEqual(TestModuleB.ELEMENTS, TestModuleA.ELEMENTS);
      return deepEqual(TestModuleA.ELEMENTS, {
        allButtons: {
          selector: 'button, [type=button]',
          global: false
        },
        inputTypeText: {
          selector: 'input[type=text]',
          global: false
        },
        someDiv: {
          selector: '.js-some-div-',
          global: false
        },
        someDivChild: {
          selector: '.js-some-div- .child',
          global: false
        },
        globalDiv: {
          selector: '.-global-div',
          global: true
        },
        all: {
          selector: '*',
          global: false
        }
      });
    });
    test("@root, @$element, @$$element", function() {
      var obj, root;
      root = $(moduleAHtmlOne);
      obj = new TestModuleA(root);
      deepEqual(root.get(), obj.root.get());
      deepEqual(root.find('button, [type=button]').get(), obj.$allButtons.get());
      return deepEqual($('.-global-div').get(), obj.$globalDiv.get());
    });
    test("methods", function() {
      return equal((new TestModuleA($([]))).getMessage(), 'hello');
    });
    test("settings", function() {
      deepEqual((new TestModuleA($('<div>'))).settings, TestModuleA.DEFAULT_SETTINGS);
      deepEqual((new TestModuleA($('<div data-baz="baz">'))).settings, TestModuleA.DEFAULT_SETTINGS);
      deepEqual((new TestModuleA($('<div data-foo="foo">'))).settings, {
        foo: 'foo',
        bar: 'default bar'
      });
      deepEqual((new TestModuleA($('<div data-foo="foo" data-bar="bar" data-baz="baz">'))).settings, {
        foo: 'foo',
        bar: 'bar'
      });
      deepEqual((new TestModuleA($('<div>'), {
        foo: 'foo',
        baz: 'baz'
      })).settings, {
        foo: 'foo',
        bar: 'default bar',
        baz: 'baz'
      });
      return deepEqual((new TestModuleA($('<div data-foo="foo" data-bar="bar">'), {
        bar: 'bar1'
      })).settings, {
        foo: 'foo',
        bar: 'bar1'
      });
    });
    test("@find()", function() {
      var obj, root;
      root = $(moduleAHtmlOne);
      obj = new TestModuleA(root);
      return deepEqual(obj.find('[type=text]').get(), root.find('[type=text]').get());
    });
    baseUpdateTest = function(updateFn) {
      return function() {
        var obj, root;
        root = $(moduleAHtmlOne);
        obj = new TestModuleA(root);
        deepEqual(obj.$inputTypeText.get(), root.find('[type=text]').get());
        root.append('<input type="text" />');
        notDeepEqual(obj.$inputTypeText.get(), root.find('[type=text]').get());
        updateFn(obj);
        return deepEqual(obj.$inputTypeText.get(), root.find('[type=text]').get());
      };
    };
    test("@updateElements()", baseUpdateTest(function(obj) {
      return obj.updateElements();
    }));
    test("@$element.update()", baseUpdateTest(function(obj) {
      return obj.$inputTypeText.update();
    }));
    baseInitTest = function(initFn) {
      return function() {
        equal(moduleACount(), 2);
        hiddenDom.append(moduleAHtmlOne);
        equal(moduleACount(), 2);
        initFn();
        equal(moduleACount(), 3);
        equal(manufactory.find(TestModuleB.NAME).length, 0);
        hiddenDom.append(moduleAHtmlOne);
        initFn($('<div>'));
        equal(moduleACount(), 3);
        initFn(hiddenDom);
        return equal(moduleACount(), 4);
      };
    };
    test("manufactory.initAll()", baseInitTest(function(context) {
      return manufactory.initAll(context);
    }));
    test("manufactory.init()", baseInitTest(function(context) {
      return manufactory.init('test.modules.A', context);
    }));
    test("$.fn.module()", function() {
      var obj1, obj2, root;
      root = $(moduleAHtmlOne);
      equal(moduleACount(), 2);
      ok(root.module('test.modules.A') instanceof TestModuleA);
      equal(moduleACount(), 3);
      obj1 = new TestModuleA(root);
      obj2 = root.module('test.modules.A');
      equal(moduleACount(), 3);
      return equal(obj1, obj2);
    });
    baseDomEventsTest = function(defineEvents) {
      return function() {
        var MyModule, root;
        MyModule = manufactory.module('test.modules.DomEventsTest', function(M) {
          var baseHandler;
          M.tree(moduleAElementsTree);
          defineEvents(M);
          baseHandler = function(getExpectedTarget) {
            return function(targetEl, event, additionalData) {
              ok(this instanceof MyModule);
              equal(targetEl, getExpectedTarget(this));
              equal(additionalData, 'additionalData');
              return equal(event.target, targetEl);
            };
          };
          return M.methods({
            onRootClicked: baseHandler(function(module) {
              return module.root[0];
            }),
            onInputChange: baseHandler(function(module) {
              return module.$$inputTypeText(':first')[0];
            }),
            onGlobalDivLicked: baseHandler(function(module) {
              return module.$globalDiv[0];
            })
          });
        });
        root = $(moduleAHtmlOne);
        manufactory.initAll(root);
        root.trigger('click', 'additionalData');
        root.find('input[type=text]:first').trigger('change', 'additionalData');
        return $('.-global-div').trigger('lick', 'additionalData');
      };
    };
    test("DOM events (M.events())", 4 * 5, baseDomEventsTest(function(M) {
      return M.events("click                  onRootClicked\nchange  inputTypeText  onInputChange\nlick    globalDiv      onGlobalDivLicked");
    }));
    test("DOM events (M.event(... root ...))", 4, baseDomEventsTest(function(M) {
      return M.event('click', 'root', 'onRootClicked');
    }));
    test("DOM events (M.event(... local element  ...))", 4, baseDomEventsTest(function(M) {
      return M.event('change', 'inputTypeText', 'onInputChange');
    }));
    test("DOM events (M.event(... local element, custom handler))", 4, baseDomEventsTest(function(M) {
      return M.event('change', 'inputTypeText', function(targetEl, event, additionalData) {
        ok(this instanceof test.modules.DomEventsTest);
        equal(targetEl, this.$$inputTypeText(':first')[0]);
        equal(additionalData, 'additionalData');
        return equal(event.target, targetEl);
      });
    }));
    return test("DOM events (M.event(... global element  ...))", 4 * 3, baseDomEventsTest(function(M) {
      return M.event('lick  ', 'globalDiv', 'onGlobalDivLicked');
    }));
  });

}).call(this);
