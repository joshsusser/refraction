require 'rack'

class Refraction
  class RequestContext
    attr_reader :env
    attr_reader :status, :message, :action

    def initialize(env)
      @action = nil
      @env = env

      hostname = env['SERVER_NAME']   # because the rack mock doesn't set the HTTP_HOST
      hostname = env['HTTP_HOST'].split(':').first if env['HTTP_HOST']
      env_path = env['PATH_INFO'] || env['REQUEST_PATH']

      @uri = URI::Generic.build(
        :scheme => env['rack.url_scheme'],
        :host   => hostname,
        :path   => env_path.empty? ? '/' : env_path
      )
      unless [URI::HTTP::DEFAULT_PORT, URI::HTTPS::DEFAULT_PORT].include?(env['SERVER_PORT'].to_i)
        @uri.port = env['SERVER_PORT']
      end
      @uri.query = env['QUERY_STRING'] if env['QUERY_STRING'] && !env['QUERY_STRING'].empty?
    end

    def response
      headers = {
        'Location' => location,
        'Content-Type' => 'text/plain',
        'Content-Length' => message.length.to_s
      }
      [status, headers, message]
    end

    # URI part accessors

    def scheme
      @uri.scheme
    end

    def host
      @uri.host
    end

    def port
      @uri.port
    end

    def path
      @uri.path
    end

    def query
      @uri.query
    end

    def method
      @env['REQUEST_METHOD']
    end

    # actions

    def set(options)
      if options.is_a?(String)
        @uri = URI.parse(options)
      else
        @uri.port = nil
        options.each do |k,v|
          k = 'scheme' if k == :protocol
          @uri.send("#{k}=", v)
        end
      end
    end

    def rewrite!(options)
      @action = :rewrite
      set(options)
    end

    def permanent!(options)
      @action = :permanent
      @status = 301
      set(options)
      @message = "moved to #{@uri}"
    end

    def found!(options)
      @action = :found
      @status = 302
      set(options)
      @message = "moved to #{@uri}"
    end

    def location
      @uri.to_s
    end

  end   # RequestContext

  def self.configure(&block)
    @rules = block
  end

  def self.rules
    @rules
  end

  def initialize(app)
    @app = app
  end

  def rules
    self.class.rules
  end

  def call(env)
    if self.rules
      context = RequestContext.new(env)

      self.rules.call(context)

      case context.action
      when :permanent, :found
        context.response
      when :rewrite
        env["rack.url_scheme"]                 = context.scheme
        env["HTTP_HOST"] = env["SERVER_NAME"]  = context.host
        env["HTTP_PORT"]                       = context.port if context.port
        env["PATH_INFO"] = env["REQUEST_PATH"] = context.path
        env["QUERY_STRING"]                    = context.query
        env["REQUEST_URI"] = context.query ? "#{context.path}?#{context.query}" : context.path
        @app.call(env)
      else
        @app.call(env)
      end
    else
      @app.call(env)
    end
  end
end
