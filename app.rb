require 'sinatra'
require 'vcr'
require 'cgi'

class App < Sinatra::Base

  set :show_exceptions, false

  configure do
    VCR.configure do |c|
      c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
      c.default_cassette_options = { :record => :none }
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
      record_mode = request.params['record_mode'].to_sym
      if request.params['cassette'] == 'create_new_cassette'
        VCR.insert_cassette(request.params["new_cassette_name"], :record => record_mode)
      else
        VCR.insert_cassette(request.params['cassette'], :record => record_mode)
      end
    end
    haml :vcr
  end

  # Handle proxied requests
  post '/request' do
    if nox_url
      resp = do_post(nox_url)
      status resp.code
      body resp.body
    else
      body "NOX_URL must be set as a request header"
      status 400
    end
  end

  private

  def do_post(uri)
    puts "*** VCR request: #{uri}"
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.post(uri.request_uri, request.body)
  end

  def nox_url
    @url ||= URI.parse(request.env['HTTP_NOX_URL']) rescue nil
  end

end
