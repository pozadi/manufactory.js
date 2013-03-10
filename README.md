
*Manufactory.js* is a small framework that allows you to create modules in such 
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


## Browser support

Manufactory.js supports all browsers that support jQuery.

See last test run on [ci.testling.com](http://ci.testling.com/pozadi/manufactory.js)


## License

The MIT License

Copyright (c) 2013 Roman Pominov

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
