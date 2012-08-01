# encoding: utf-8
require 'spec_helper'

describe Tiny::Widget do
  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe "page widget" do
    before do
      @output = Class.new(Tiny::Widget) do
        def content
          head { title "Tiny Page!" }
          body { h1 "Hello Tiny!" }
        end
      end.new.render
    end

    it { output.should have_css 'head', :count => 1 }
    it { output.should have_css 'head > title', :text => "Tiny Page!", :count => 1 }
    it { output.should have_css 'body', :count => 1 }
    it { output.should have_css 'body > h1', :text => "Hello Tiny!", :count => 1 }
  end
end
