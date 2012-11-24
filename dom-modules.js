// Generated by CoffeeScript 1.4.0
(function() {
  var action,
    __slice = [].slice;

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
