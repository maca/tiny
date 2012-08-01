# encoding: utf-8
require 'spec_helper'

describe Tiny::Widget do
  include Tiny::Helpers

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

  describe 'content from different methods' do
    before do
      @output = Class.new(Tiny::Widget) do
        def notices
          div :id => :notices do
            h1 'Notices'
          end
        end

        def main
          div :id => :content do
            h1 "Content"
          end
        end

        def content
          notices
          main
        end
      end.new.render
    end

    it { output.should have_css 'div#notices', :count => 1 }
    it { output.should have_css 'div#notices > h1', :text => "Notices", :count => 1 }
    it { output.should have_css 'div#content', :count => 1 }
    it { output.should have_css 'div#content > h1', :text => "Content", :count => 1 }
  end

  describe 'rendering a block from outside' do
    before do
      @title  = "Content" # no need to smuggle instance variables 
      @output = Class.new(Tiny::Widget) do
        def content
          div :id => :content do
            yield
          end
        end
      end.new.render { tag :h1, @title }
    end

    it { output.should have_css 'div#content', :count => 1 }
    it { output.should have_css 'div#content > h1', :text => "Content", :count => 1 }
  end

  describe 'rendering a block from outside with concatenated tags' do
    before do
      @output = Class.new(Tiny::Widget) do
        def content &block
          div(:id => :content, &block)
        end
      end.new.render { tag(:h1, "Title"); tag(:p, "Content") }
    end

    it { output.should have_css 'div#content', :count => 1 }
    it { output.should have_css 'div#content > h1', :text => "Title", :count => 1 }
    it { output.should have_css 'div#content > p', :text => "Content", :count => 1 }
  end

  describe 'widget with no content overriden' do
    it 'should raise not implemented' do
      lambda do
        Class.new(Tiny::Widget).new.render
      end.should raise_error(NotImplementedError)
    end
  end
end
