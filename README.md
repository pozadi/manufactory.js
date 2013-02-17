*manufactory.js* is a small framework that allows you to create modules in such 
style:

```html
<script type="text/coffeescript">
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
      showMessage: -> alert @input.val()
</script>

<div class=js-my-module>
  <input class=js-input>
  <button class=js-button>show message</button>
</div>
```

[play online](http://jsfiddle.net/MpXtH/)

See also [more complex example](http://jsfiddle.net/Bh3e2/1/)
