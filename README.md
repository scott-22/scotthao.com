# Scott's Personal Website

My personal website, written with Common Lisp.

## Framework

This website comes with a custom web framework, building on top of the open source Clack server.
Similar to other web frameworks, you can define endpoint or error handlers that take a request as input and produce HTML as output.
It also comes with a templating system supporting both static and dynamic (SSR) pages - the templating language is unsurprisingly Lisp itself.

### Routes
Define route handlers in a file under `src/controllers`.
```lisp
;; Ensure you are in the `controllers` package
(in-package controllers)

;; Syntactically, route definitions are similar to function definitions
(defroute "/example/path" :GET (env) ...)
(defroute 404 (env) ...)

;; Add a colon to use route parameters
(defroute "/users/:value" :ALL (env) ...)
```
As input, routes will receive a single argument `env`, a plist of request data. Note that when using route parameters, an entry with key `:route-params` is added to `env`, which is a plist of all route parameters. See the [Clack docs](https://github.com/fukamachi/clack) for details on `env`, as well as the expected output.

Currently, when specifying the request method, exactly one of `:GET`, `:HEAD`, `:OPTIONS`, `:PUT`, `:POST`, or `:DELETE` should be used. To bind the handler to every method, use `:ALL`.

### Templates
Why write HTML when you can write Lisp? Templates should be defined under `templates/static` or `templates/dynamic` depending on the type. Static templates are compiled exactly once, while dynamic templates are re-compiled every request. Templates are simply files containing a special Lisp function that produces HTML using the Spinneret `with-html` macro. See the [Spinneret docs](https://github.com/ruricolist/spinneret) for more details.

Note: dynamic templates will probably overwrite each other under race conditions. Suffice to say, please do not use this in prod.

To define a template called `my-template`, create a file with the same name (`my-template.lisp`) under the correct directory.
```lisp
;; my-template.lisp
;; Ensure you are in the `templates` package
(in-package :templates)

;; You can optionally define utility macros in other files
(load "templates/utils.lisp")

;; Define a function called `my-template`
(defun my-template () ...) ; 0-arg or static template
(defun my-template (data1 data2) ...) ; dynamic template
```
Note that dynamic templates will take all their data as arguments. There should be no free variables.

Once a template has been defined, it can be used from a route with the `template` function.
```lisp
(in-package controllers)

;; To render a static template called `my-static`
(defroute "/static/template" :GET (env)
  `(200 (:content-type "text/html") ,(template "my-static" :static)))

;; To render a dynamic template called `my-dynamic`
(defroute "/static/template" :GET (env)
  (let* ((data1 ...)
         (data2 ...))
    `(200 (:content-type "text/html") ,(template "my-dynamic" :dynamic data1 data2))))
```

## Development

To develop, run the Docker container while setting the target env variable to `dev`:
1. `TARGET=dev docker compose build site`
1. `docker compose up site`
1. Use editor of choice to edit the project
1. To access dev utilities, connect to port `4005` using emacs with SLIME (`M-x slime-connect` with default settings) and open a REPL

If using dev utilities, you can recompile the website from the REPL with `(rl)`. See `devutils.lisp` for all utilities.

## Deployment

To deploy, simply build and run the production image (default target if using Docker compose).  This can then be deployed to the cloud, to a VPS, etc.
If handling deployment manually (such as to a VPS), consider running a web server like NGINX and forwarding traffic to the container.
