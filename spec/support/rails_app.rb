Rails.logger = Logger.new(STDOUT)
Rails.logger.level = 3

ActionController::Base.view_paths = FIXTURES

module RailsTestApp
  class Application < Rails::Application
    config.secret_token = '572c86f5ede338bd8aba8dae0fd3a326aabababc98d1e6ce34b9f5'

    routes.draw do
      get '/haml'        => 'rails_test_app/test#haml'
      get '/erb'         => 'rails_test_app/test#erb'
      get '/erb_helpers' => 'rails_test_app/test#erb_helpers'
    end
  end

  class TestController < ActionController::Base
    helper do
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::UrlHelper
      include ListHelper
    end

    def erb
      render :template => "erb_list"
    end

    def erb_helpers
      render :template => "erb_list_with_helpers"
    end

    def haml
      render :template => "haml_list"
    end
  end
end

require 'haml/template'
