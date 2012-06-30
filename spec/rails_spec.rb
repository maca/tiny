require 'spec_helper'
require "#{SUPPORT}/rails_app"

describe 'Rails compatibility', :type => :request do
  include Rack::Test::Methods

  let(:output) do
    Capybara::Node::Simple.new(page.body)
  end

  before do
    Capybara.app = RailsTestApp::Application
  end

  describe 'using Tiny from erb template' do
    before do
      visit '/erb'
    end
    it_should_behave_like 'it renders my list'
  end

  describe 'using Tiny helpers from erb template' do
    before do
      visit '/erb_helpers'
    end
    it_should_behave_like 'it renders my list'
  end
end
