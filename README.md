*manufactory.js* is a small framework that allows you to create modules in such 
style:

```coffeescript
manufactory.module 'MyModule', (M) ->
  M.tree """
    .js-my-module
      .js-input
      .js-button
  """
  M.events """
    click button showMessage
  """
  M.methods
      showMessage: -> alert @el.input.val()
```

```html
<div class=js-my-module>
  <input class=js-input>
  <button class=js-button>show message</button>
</div>
```

[play online](http://jsfiddle.net/MpXtH/1/)

See also [more complex example](http://jsfiddle.net/Bh3e2/2/)
