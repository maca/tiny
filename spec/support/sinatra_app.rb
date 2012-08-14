require 'sinatra'

class SinatraTestApp < Sinatra::Base
  enable :sessions
  set :environment, :test
  set :views, "#{File.dirname __FILE__}/../fixtures"

  helpers Tiny::Helpers
  helpers ListHelper

  get '/erb' do
    erb :erb_list
  end

  get '/haml' do
    haml :haml_list
  end

  get '/erb_helpers' do
    erb :erb_list_with_helpers
  end

  get '/haml_helpers' do
    haml :haml_list_with_helpers
  end
end
