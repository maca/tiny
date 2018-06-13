Rails.logger = Logger.new(STDOUT)
Rails.logger.level = 3

ActionController::Base.view_paths = FIXTURES

module RailsTestApp
  class Application < Rails::Application
    routes.draw do
      get '/erb'          => 'rails_test_app/test#erb'
      get '/erb_helpers'  => 'rails_test_app/test#erb_helpers'
      get '/haml'         => 'rails_test_app/test#haml'
      get '/haml_helpers' => 'rails_test_app/test#haml_helpers'
    end
  end

  class TestController < ActionController::Base
    helper do
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::UrlHelper
      include ListHelper
    end

    def erb
      render template: "erb_list"
    end

    def erb_helpers
      render template: "erb_list_with_helpers"
    end

    def haml
      render template: "haml_list"
    end

    def haml_helpers
      render template: "haml_list_with_helpers"
    end
  end
end

# Rails app boot
require 'haml/template'
