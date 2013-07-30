require 'sinatra'
require 'vcr'
require 'cgi'
require 'pry'
require 'pry-debugger'

class App < Sinatra::Base

  set :show_exceptions, false

  configure do
    VCR.configure do |c|
      c.cassette_library_dir = "spec/fixtures"
      c.default_cassette_options = { :record => :none, :allow_playback_repeats => true }
      c.stub_with :webmock
    end
  end

  helpers do

    # From https://github.com/unixcharles/vcr-remote-controller

    def cassettes
      Dir["#{VCR::configuration.cassette_library_dir}/**/*.yml"].map do |f|
        f.match(/^#{Regexp.escape(VCR::configuration.cassette_library_dir.to_s)}\/(.+)\.yml/)[1]
      end
    end

    def current_cassette
      VCR.current_cassette ? VCR.current_cassette.name : nil
    end

    def current_cassette_new_recorded_interactions
      VCR.current_cassette.new_recorded_interactions.map(&:to_yaml).join("\n\n") if cassette?
    end

    def cassette?
      VCR.current_cassette
    end

    def current_cassette_empty?
      VCR.current_cassette.new_recorded_interactions.size == 0 if cassette?
    end

    def current_cassette_record_mode
      VCR.current_cassette.record_mode if cassette?
    end

    def default_record_mode
      VCR::configuration.default_cassette_options[:record]
    end

  end

  # Configure VCR
  get '/vcr' do
    haml :vcr
  end

  post '/vcr' do
    VCR.eject_cassette if cassette?
    unless request.params['submit'] == 'Eject'
      VCR.insert_cassette(request.params['cassette'], :record => :none)
    end
    haml :vcr
  end

  # Handle proxied requests
  post '/request' do
    unless nox_url
      body "HTTP_NOX_URL must be set as a request header"
      status 400
      return
    end

    http = Net::HTTP.new(nox_url.host, nox_url.port)
    http.use_ssl = nox_url.scheme == "https"
    method = request.env["HTTP_NOX_METHOD"]
    puts "*** VCR #{method} request: #{nox_url}"
    if (method == "POST")
      resp = http.post(nox_url.request_uri, request.body)
    else
      resp = http.get(nox_url.request_uri)
    end
    status resp.code
    body resp.body
  end

  def nox_url
    @url ||= URI.parse(request.env['HTTP_NOX_URL'])
  end

end
