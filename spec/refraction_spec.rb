require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), "..", "lib", "refraction")

describe Refraction do

  describe "if no rules have been configured" do
    before do
      Refraction.configure
    end

    it "does nothing" do
      env = Rack::MockRequest.env_for('http://bar.com/about', :method => 'get')
      app = mock('app')
      app.should_receive(:call) { |resp|
        resp['rack.url_scheme'].should == 'http'
        resp['SERVER_NAME'].should == 'bar.com'
        resp['PATH_INFO'].should == '/about'
        [200, {}, ["body"]]
      }
      response = Refraction.new(app).call(env)
    end
  end

  describe "path" do
    before do
      Refraction.configure do |req|
        if req.path == '/'
          req.permanent! 'http://yes.com/'
        elsif req.path == ''
          req.permanent! 'http://no.com/'
        end
      end
    end

    it "should be set to / if empty" do
      env = Rack::MockRequest.env_for('http://bar.com', :method => 'get')
      env['PATH_INFO'] = '/'
      app = mock('app')
      response = Refraction.new(app).call(env)
      response[0].should == 301
      response[1]['Location'].should == "http://yes.com/"
    end
  end

  describe "permanent redirection" do

    describe "using string arguments" do
      before do
        Refraction.configure do |req|
          req.permanent! "http://foo.com/bar?baz"
        end
      end

      it "should redirect everything to foo.com" do
        env = Rack::MockRequest.env_for('http://bar.com', :method => 'get')
        app = mock('app')
        response = Refraction.new(app).call(env)
        response[0].should == 301
        response[1]['Location'].should == "http://foo.com/bar?baz"
      end
    end

    describe "using hash arguments" do
      before do
        Refraction.configure do |req|
          req.permanent! :host => "foo.com", :path => "/bar", :query => "baz"
        end
      end

      it "should redirect http://bar.com to http://foo.com" do
        env = Rack::MockRequest.env_for('http://bar.com', :method => 'get')
        app = mock('app')
        response = Refraction.new(app).call(env)
        response[0].should == 301
        response[1]['Location'].should == "http://foo.com/bar?baz"
      end

      it "should redirect https://bar.com to https://foo.com" do
        env = Rack::MockRequest.env_for('https://bar.com', :method => 'get')
        app = mock('app')
        response = Refraction.new(app).call(env)
        response[0].should == 301
        response[1]['Location'].should == "https://foo.com/bar?baz"
      end

      it "should clear the port unless set explicitly" do
        env = Rack::MockRequest.env_for('http://bar.com:3000/', :method => 'get')
        app = mock('app')
        response = Refraction.new(app).call(env)
        response[0].should == 301
        response[1]['Location'].should == "http://foo.com/bar?baz"
      end
    end
  end

  describe "temporary redirect for found" do
    before(:each) do
      Refraction.configure do |req|
        if req.path =~ %r{^/users/(josh|edward)/blog\.(atom|rss)$}
          req.found! "http://feeds.pivotallabs.com/pivotallabs/#{$1}.#{$2}"
        end
      end
    end

    it "should temporarily redirect to feedburner.com" do
      env = Rack::MockRequest.env_for('http://bar.com/users/josh/blog.atom', :method => 'get')
      app = mock('app')
      response = Refraction.new(app).call(env)
      response[0].should == 302
      response[1]['Location'].should == "http://feeds.pivotallabs.com/pivotallabs/josh.atom"
    end

    it "should not redirect when no match" do
      env = Rack::MockRequest.env_for('http://bar.com/users/sam/blog.rss', :method => 'get')
      app = mock('app')
      app.should_receive(:call) { |resp|
        resp['rack.url_scheme'].should == 'http'
        resp['SERVER_NAME'].should == 'bar.com'
        resp['PATH_INFO'].should == '/users/sam/blog.rss'
        [200, {}, ["body"]]
      }
      response = Refraction.new(app).call(env)
    end
  end

  describe "rewrite url" do
    before(:each) do
      Refraction.configure do |req|
        if req.host =~ /(tweed|pockets)\.example\.com/
          req.rewrite! :host => 'example.com', :path => "/#{$1}#{req.path == '/' ? '' : req.path}"
        end
      end
    end

    it "should rewrite subdomain to scope the path for matching subdomains" do
      env = Rack::MockRequest.env_for('http://tweed.example.com', :method => 'get')
      app = mock('app')
      app.should_receive(:call) { |resp|
        resp['rack.url_scheme'].should == 'http'
        resp['SERVER_NAME'].should == 'example.com'
        resp['PATH_INFO'].should == '/tweed'
        [200, {}, ["body"]]
      }
      Refraction.new(app).call(env)
    end

    it "should not rewrite if the subdomain does not match" do
      env = Rack::MockRequest.env_for('http://foo.example.com', :method => 'get')
      app = mock('app')
      app.should_receive(:call) { |resp|
        resp['rack.url_scheme'].should == 'http'
        resp['SERVER_NAME'].should == 'foo.example.com'
        resp['PATH_INFO'].should == '/'
        [200, {}, ["body"]]
      }
      Refraction.new(app).call(env)
    end
  end

  describe "environment" do
    before(:each) do
      Refraction.configure do |req|
        if req.env['HTTP_USER_AGENT'] =~ /FeedBurner/
          req.permanent! "http://yes.com/"
        else
          req.permanent! "http://no.com/"
        end
      end
    end

    it "should expose environment settings" do
      env = Rack::MockRequest.env_for('http://foo.com/', :method => 'get')
      env['HTTP_USER_AGENT'] = 'FeedBurner'
      app = mock('app')
      response = Refraction.new(app).call(env)
      response[0].should == 301
      response[1]['Location'].should == "http://yes.com/"
    end
  end
end
