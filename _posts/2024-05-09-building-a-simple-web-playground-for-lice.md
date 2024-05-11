---
layout: post
author: gabyfle
title: Building a simple web playground for Lice
---

[Lice](https://lice.gabyfle.dev) is a project on which I'm working since October 2023. It's a little and simple programming language project that I started as a little side project to learn more on the way we build programming language today. Recently, I just switched the interpretation process from a basic and simple *tree-walk* interpreter to a yet to be polished *bytecode* interpreter. *Note that neither the Lice library or the language in itself is finished at the time I'm writing this blog post.*

As the language gained with execution speed and memory usage, I wanted to build something similar to [Rust's Playground](https://play.rust-lang.org/) for te sake of demonstration on how does Lice works internally, and also to have a handy debugger that I can use interactively on my web browser. Also, creating such a thing was a nice first example and POC on how one can use the Lice library to build something usefull.

### Using the power of `js_of_ocaml`

`js_of_ocaml` (or `jsoo` for short) is an OCaml backend that compiles OCaml's bytecode into Javascript. In order to build our web playground, we're going to compile our Lice libraries into Javascript, and ship the build artifacts directly into a static webpage. After downloading and installing the Lice libraries using these commands:

```bash
git clone https://github.com/gabyfle/Lice.git && cd Lice && opam install .
```

We can start creating a new `dune` project with the `js_of_ocaml` library and PPX rewriter.

```ocaml
(executable
  (name playground)
  (libraries js_of_ocaml lice)
  (modes js)
  (preprocess
   (pps js_of_ocaml−ppx)))
```

`jsoo` is exposing some utility functions to expose OCaml functions to the Javascript realm by using the `JS.export` function. For the sake of simplicity, we're not going to manipulate the DOM directly throught OCaml code, as we're going to use the dope open-source web editor [Ace](https://ace.c9.io/) to create our playground. Inside a playground, each run is made in a completely new context, thus we do not need to save the Lice state each time we're executing code from the editor. Before starting to write the functions that we'll need to write the web editor, we need to open the Lice library as well as the `jsoo` ones inside our `playground.ml` file:

```ocaml
open Lice
open Js_of_ocaml
```

The first function that we need is of course a way to execute the source code from the editor. To do so, we're going to expose a function that takes a `string` representing a Lice program and execute it inside an empty state:

```ocaml
let exec_string (str: string) =
  let state = LState.empty in
  let state = LState.do_string state str in
  state
```

To make our playground a little bit more usefull, something nice would be to have a bytecode explorer so that we can dig inside the internals of the language. The Lice library expose a `bytecode_viewer` function that takes a string and compiles it to a bytecode, then pretty-prints it into a string.

Internally, we're just replacing the interpretation step by a pretty-printing step: the code is compiled as if it was going to be executed but we then read the outputed bytecode and build a string representation of it.

To expose these two functions, it simple as this:

```ocaml
let _ =
  Js.export "Lice"
    (object%js
      method doString (code: string) = exec_string code
      method bytecodeViewer = Lice.bytecode_viewer
    end)
```

So, our final `playground.ml` file should looks something like this:

```ocaml
open Lice
open Js_of_ocaml

let exec_string (str: string) =
  let state = LState.empty in
  let state = LState.do_string state str in
  state

let _ =
  Js.export "Lice"
    (object%js
      method doString (code: string) = exec_string code
      method bytecodeViewer = Lice.bytecode_viewer
    end)

```

### A super simple integration with ACE

Few days ago I found this super dope web editor framework called [Ace](https://ace.c9.io/) that offers a very nice Javascript API. I'm not at all a web developer (my skills in this area are near zero), and I also don't know Javascript. Thanksfully, the API is pretty simple. Warning here, maybe I could've made a better integration of the editor if only I had a better knowledge of this incredible language (*/s*).

{% include images.html url="/assets/images/posts/2024-05-09/jsmeme.png" description="Javascript is definitely a good programming language" %}

When building with `dune build`, `jsoo` will output a file called `playground.bc.js` which is our entry point for using the Lice interpreter. We're going to use this simple HTML skeleton for the playground, put inside a `playground.html` file.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lice - Playground</title>
    <link href="assets/playground.css" rel="stylesheet">
</head>
<body>
    <a id="run-btn">Run</a>
    <pre id="editor"></pre>
    <pre id="bytecode"></pre>
    <pre id="output"></pre>
</body>
<script src="assets/ace/src-min-noconflict/ace.js" type="text/javascript" charset="utf-8"></script>
<script src="assets/playground.bc.js"></script>
<script src="assets/playground.js"></script>
</html>
```

In this configuration, the `editor` element is going to be the place where the Lice code is written,  the `bytecode` element the place where the code bytecode is displayed and the `output` element where the output (if there are any) is shown.

To access to these elements and tell `ace` that these should be editors, we can use the `edit` method of the `ace` library.

```js
var editor = ace.edit("editor");

var bytecode = ace.edit("bytecode");
    /* the bytecode editor shouldn't be editable */
    bytecode.setReadOnly(true);

var output = ace.edit("output");
    /* the output editor shouldn't be editable */
    output.setReadOnly(true);
```

The functions we exposed from OCaml are available in the `Lice` namespace as we defined earlier. We have two functions available, one to execute the code, the other to get a string representing the bytecode. For the sake of adding a litte more functionnality, we're going to record the execution time of the source code taken from the main editor. We can use the `Lice.doString` function to execute the code, by simply passing the data inside the `editor`. Below is the resulting Javascript `doString` function that we're going to use. Note that we could make use of asynchronous programming with Javascripts promises system, but for the sake of simplicity (yes, again), we're not going to here.

```js
function doString() {
    let start = performance.now();
    let code = editor.getValue();

    try {
        Lice.doString(code);
        let state = Lice.doString(code);
        let end = performance.now();

        return [state, (end - start)];
    } catch (e) {
        return [e, "Error."];
    }
}
```

This function returns also the state in which the code has been executed, if we later want to get some data from the state (like dumping the stack, getting the accumulator value, or anything else). In the same vein, we're going to use the `bytecode_viewer` function exposed from OCaml to create our nice bytecode explorer:

```js
function updateBytecode() {
    let code = editor.getValue();
    try {
        let bc = Lice.bytecodeViewer(code);
        bytecode.setValue(bc);
    } catch (e) {
        bytecode.setValue("");
        return;
    }
}
```

The last thing to do is to trigger the execution of the script and the bytecode explorer once the Run button has been clicked on. This is the final `playground.js` file that we're going to use:

```js
function runClicked() {
        let [state, time] = doString();
        updateBytecode();
        var tString = "Execution time: " + (Math.round(time)).toString() + "ms";
        output.setValue(tString);
}

function doString() {
    let start = performance.now();
    let code = editor.getValue();

    try {
        Lice.doString(code);
        let state = Lice.doString(code);
        let end = performance.now();

        return [state, (end - start)];
    } catch (e) {
        return [e, "Error."];
    }
}

function updateBytecode() {
    let code = editor.getValue();
    try {
        let bc = Lice.bytecodeViewer(code);
        bytecode.setValue(bc);
    } catch (e) {
        bytecode.setValue("");
        return;
    }
}

document.querySelector("#run-btn").addEventListener("click", runClicked);
```

And voilà ! We got a fully working (very) simple playground for Lice that even allows us to dig inside the bytecode. This is a great example of the usages that can be made by this library when you combine it to the strenght of such thing that is `jsoo`. Creating a little POC like this has driven me to add few functions to the Lice library, and that's why I think it is important to be a consumer of the library you write. A live version (with added CSS) is available [here](https://lice.gabyfle.dev/playground.html).

Some things can be of course improved and here is a non-exhaustive list:

- Running the code using Javascript promises to create a non-blocking experience while running long programs
- Improving the overall user experience by allowing resizing the editor windows

Of course, all of this is open source and available at the [Github repository](https://github.com/gabyfle/Lice/). Feel free to open a pull request if you want to improve the online editor.

gabyfle.
