require 'sinatra'
require 'vcr'
require 'cgi'

set :port, 7654

VCR.config do |c|
  c.cassette_library_dir = "/Users/petermoran/workspace/jetstar/newco/spec/fixtures/vcr_cassettes"
  c.default_cassette_options = { :record => :none }
  c.stub_with :webmock
end

get '/vcr' do
  erb :vcr
end

post '/vcr' do
  VCR.eject_cassette if cassette?
  unless request.params['submit'] == 'Eject'
    if request.params['cassette'] == 'create_new_cassette'
      VCR.insert_cassette(request.params["new_cassette_name"], :record => request.params['record_mode'].to_sym)
    else
      VCR.insert_cassette(request.params['cassette'], :record => request.params['record_mode'].to_sym)
    end
  end
  erb :vcr
end


post '/request' do
  uri = URI.parse(request.env['HTTP_NOX_URL'])
  puts "*** VCR request: #{uri}"
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  resp = http.post(uri.request_uri, request.body)
  status resp.code
  body resp.body
end

helpers do

  def cassettes
    Dir["#{VCR::Config.cassette_library_dir}/**/*.yml"].map do |f|
      f.match(/^#{Regexp.escape(VCR::Config.cassette_library_dir.to_s)}\/(.+)\.yml/)[1]
    end
  end

  def current_cassette
    VCR.current_cassette ? VCR.current_cassette.name : nil
  end

  def current_cassette_new_recorded_interactions
    VCR.current_cassette.new_recorded_interactions.map(&:to_yaml).join("\n\n") if cassette?
  end

  def cassette?
    !(VCR.current_cassette == nil)
  end

  def current_cassette_empty?
    VCR.current_cassette.new_recorded_interactions.size == 0 if cassette?
  end

  def current_cassette_record_mode
    VCR.current_cassette.record_mode if cassette?
  end

  def default_record_mode
    VCR::Config.default_cassette_options[:record]
  end

  def current_cassette_status
    if cassette?
      %Q{<p>Current cassette: <b>#{current_cassette}</b> #{ '- (empty)' if current_cassette_empty? }</p>
         <p>Record mode: <b>:#{current_cassette_record_mode}</b></p>}
     else
       '<p>No cassette in the VCR</p>'
     end
   end

   def cassettes_radio_fields
     cassettes.map do |cassette|
       cassette_name = CGI::escapeHTML(cassette)
       selected = current_cassette == cassette
       %Q{<p><label><input type="radio" name="cassette" value="#{cassette_name}"#{' checked' if selected}>#{cassette_name}</label></p>}
      end.join("\n")
    end

    def record_modes_fields
      [:once, :new_episodes, :none, :all].map do |record_mode|
        %Q{<label><input type="radio" name="record_mode" value="#{record_mode}"#{ ' checked' if record_mode == default_record_mode}>:#{record_mode}</label>}
      end.join("\n")
    end

     def new_recored_information
       %Q{<p>New recorded interactions</p>
          <hr/>
          <pre><code>
          #{ CGI::escapeHTML current_cassette_new_recorded_interactions }
          </code></pre>} if cassette? and !(current_cassette_empty?)
     end

end
