require 'sinatra'

class TestSinatraApp < Sinatra::Base
  enable :sessions
 
  get '/erb' do
  end
 
  post '/haml' do
  end
end
