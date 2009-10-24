Refraction
==========

Refraction is a Rack middleware replacement for `mod_rewrite`. It can rewrite URLs before they are
processed by your web application, and can redirect using 301 and 302 status codes. Refraction is
thread-safe, so it doesn't need to be guarded by Rack::Lock.

The best thing about Refraction is that rewrite rules are written in plain old Ruby code, not some
funky web server config syntax. That means you can use Ruby regular expressions, case statements,
conditionals, and whatever else you feel like.

For example:

    Refraction.configure do |req|
      feedburner  = "http://feeds.pivotallabs.com/pivotallabs"

      if req.env['HTTP_USER_AGENT'] !~ /FeedBurner|FeedValidator/ && req.host =~ /pivotallabs\.com/
        case req.path
        when %r{^/(talks|blabs|blog)\.(atom|rss)$}        ; req.found! "#{feedburner}/#{$1}.#{$2}"
        when %r{^/users/(chris|edward)/blog\.(atom|rss)$} ; req.found! "#{feedburner}/#{$1}.#{$2}"
        end
      else
        case req.host
        when 'tweed.pivotallabs.com'
          req.rewrite! "http://pivotallabs.com/tweed#{req.path}"
        when /([-\w]+\.)?pivotallabs\.com/
          # passthrough with no change
        else  # wildcard domains (e.g. pivotalabs.com)
          req.permanent! :host => "pivotallabs.com"
        end
      end
    end

Notice the use of regular expressions, the $1, $2, etc pseudo-variables, and string interpolation.
This is an easy way to match URL patterns and assemble the new URL based on what was matched.

## Installation (Rails)

Refraction can be installed in a Rails application as a plugin.

    $ script/plugin install git://github.com/pivotal/refraction.git

In `environments/production.rb`, add Refraction at or near the top of your middleware stack.

    config.middleware.insert_before(::Rack::Lock, ::Refraction, {})

You may want to occasionally turn on Refraction in the development environment for testing
purposes, but if your rules redirect to other servers that can be a problem.

Put your rules in `config/initializers/refraction_rules.rb` (see example above). The file name
doesn't actually matter, but convention is useful.

## Server Configuration

If your application is serving multiple virtual hosts, it's probably easiest to configure your web
server to handle a wildcard server name and let Refraction handle managing the virtual hosts. For
example, in nginx, that is done with a `server_name _;` directive.

## Writing Rules

Set up your rewrite/redirection rules during your app initialization using `Refraction.configure`.
The `configure` method takes a block which is run for every request to process the rules. The block
is passed a RequestContext object that contains information about the request URL and environment.
The request object also has a small API for effecting rewrites and redirects.

> Important note: don't do a `return` from within the configuration
> block.  That would be bad (meaning your entire application would
> break).  That's just how blocks work in Ruby.

### `RequestContext#set(options)`

The `set` method takes an options hash that sets pieces of the rewritten URL or redirect location
header.

  * :scheme - Usually `http` or `https`.
  * :host - The server name.
  * :port - The server port.  Usually not needed, as the scheme implies a default value.
  * :path - The path of the URL.
  * :query - Added at the end of the URL after a question mark (?)

Any URL components not explicitly set remain unchanged from the original request URL. You can use
`set` before calls to `rewrite!`, `permanent!`, or `found!` to set common values. Subsequent
methods will merge their component values into values from `set`.

### `RequestContext#rewrite!(options)`

The `rewrite!` method modifies the request URL and relevant pieces of the environment. When
Refraction rule processing results in a `rewrite!`, the request is passed on down the Rack stack
to the app or the next middleware component. `rewrite!` can take a single argument, either an
options hash that uses the same options as the `set` method, or a string that sets all components
of the URL.

### `RequestContext#permanent!(options)`

The `permanent!` method tells Refraction to return a response with a `301 Moved Permanently`
status, and sets the URL for the Location header. Like `rewrite!` it can take either a string or
hash argument to set the URL or some of its components.

### `RequestContext#found!(options)`

The `found!` method tells Refraction to return a response with a `302 Found` status, and sets the
URL for the Location header. Like `#rewrite!` it can take either a string or hash argument to set
the URL or some of its components.

### URL components

The request object provides the following components of the URL for matching requests: `scheme`,
`host`, `port`, `path`, and `query`. It also provides a full environment hash as the `env`
attribute. For example, `req.env['HTTP_USER_AGENT']` can be used to access the request's user
agent property.

## Contributors

  * Josh Susser (maintainer)
  * Sam Pierson
  * Wai Lun Mang

