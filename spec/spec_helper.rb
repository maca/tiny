require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'capybara/rspec'
# require 'erubis'
require 'rails'
require 'action_controller/railtie'
require 'haml'
require 'sinatra'
require 'tiny'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'support/list_helper'

RSpec.configure do |config|
  config.include Capybara::DSL,       type: :request
  config.include Rack::Test::Methods, type: :request
end

FIXTURES = "#{File.dirname __FILE__}/fixtures"
SUPPORT  = "#{File.dirname __FILE__}/support"

shared_examples_for 'it renders my list' do
  it { expect(output).to have_css 'ul',    count: 1 }
  it { expect(output).to have_css 'li',    count: 3 }
  it { expect(output).to have_css 'a',     count: 3 }
  it { expect(output).to have_css 'span',  count: 3 }
  it { expect(output).to have_css 'ul > li' }
  it { expect(output).to have_css 'ul > li > a' }
  it { expect(output).to have_css 'ul > li > a', text: 'A' }
  it { expect(output).to have_css 'ul > li > a > span', text: '1' }
  it { expect(output).to have_css 'ul > li > a', text: 'B' }
  it { expect(output).to have_css 'ul > li > a > span', text: '2' }
  it { expect(output).to have_css 'ul > li > a', text: 'C' }
  it { expect(output).to have_css 'ul > li > a > span', text: '3' }
end

shared_examples_for 'it renders my form' do
  it { expect(output).to have_css 'form', count: 1 }
  it { expect(output).to have_css 'form[action="/login"]', count: 1 }
  it { expect(output).to have_css 'form > fieldset', count: 1 }
  it { expect(output).to have_css 'form > fieldset > label', count: 1 }
  it { expect(output).to have_css 'form > fieldset > label[for=email]', text: 'Email', count: 1 }
  it { expect(output).to have_css 'form > fieldset > input', count: 1 }
  it { expect(output).to have_css 'form > fieldset > input#email[type=text][value="email@example.com"]', count: 1 }
end

class Renderer
  include Tiny::Helpers
  include ListHelper

  def initialize(template)
    @template = template
  end

  def render
    Tilt.new("#{FIXTURES}/#{@template}", outvar: '@output').render(self)
  end
end
