require 'tiny'
module Tiny
  class Railtie < Rails::Railtie
    initializer "tiny.helper" do
      puts 'Actionview'
      ActionView::Base.send :include, Helper
    end
  end
end
