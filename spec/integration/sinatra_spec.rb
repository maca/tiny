require 'spec_helper'
require "#{SUPPORT}/sinatra_app"

describe 'Sinatra compatibility', type: :request do
  let(:output) do
    Capybara::Node::Simple.new(page.body)
  end

  before do
    Capybara.app = SinatraTestApp
  end

  describe 'using Tiny from erb template' do
    before do
      visit '/erb'
    end
    it_behaves_like 'it renders my list'
  end

  describe 'using Tiny helpers from erb template' do
    before do
      visit '/erb_helpers'
    end
    it_behaves_like 'it renders my list'
  end

  describe 'using Tiny from haml template' do
    before do
      visit '/haml'
    end
    it_behaves_like 'it renders my list'
  end

  describe 'using Tiny helpers from haml template' do
    before do
      visit '/haml_helpers'
    end
    it_behaves_like 'it renders my list'
  end
end
