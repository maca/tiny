# encoding: utf-8
require 'spec_helper'

describe Tiny::Widget do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end
  
  describe "simple widget" do
    it 'should output content' do
      output = Class.new(Tiny::Widget) do
        def markup
          text! '<div></div>'
        end
      end.new.to_html
      output.should == "<div></div>\n"
    end

    it 'should output content with block' do
      output = Class.new(Tiny::Widget) do
        def markup
          tiny_concat "<div>"
          yield
          tiny_concat "</div>"
        end
      end.new.to_html { text 'Hello' }
      output.should == "<div>\nHello\n</div>\n"
    end
  end

  describe "page widget" do
    before do
      @output = Class.new(Tiny::Widget) do
        def markup
          head { title "Tiny Page!" }
          body { h1 "Hello Tiny!" }
        end
      end.new.to_html
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

        def markup
          notices
          main
        end
      end.new.to_html
    end

    it { output.should have_css 'div#notices', :count => 1 }
    it { output.should have_css 'div#notices > h1', :text => "Notices", :count => 1 }
    it { output.should have_css 'div#content', :count => 1 }
    it { output.should have_css 'div#content > h1', :text => "Content", :count => 1 }
  end

  describe 'rendering a tag from outside' do
    before do
      @title  = "Content" # no need to smuggle instance variables 
      @output = Class.new(Tiny::Widget) do
        def markup
          div :id => :content do
            yield
          end
        end
      end.new.to_html { tag :h1, @title }
    end

    it { output.should have_css 'div#content', :count => 1 }
    it { output.should have_css 'div#content > h1', :text => "Content", :count => 1 }
  end

  describe 'rendering a block from outside with concatenated tags' do
    before do
      @output = Class.new(Tiny::Widget) do
        def markup &block
          div(:id => :content, &block)
        end
      end.new.to_html { tag(:h1, "Title"); tag(:p, "Content") }
    end

    it { output.should have_css 'div#content', :count => 1 }
    it { output.should have_css 'div#content > h1', :text => "Title", :count => 1 }
    it { output.should have_css 'div#content > p', :text => "Content", :count => 1 }
  end

  describe 'rendering an erb block' do
    before do
      widget = Class.new(Tiny::Widget) do
        def markup &block
          div(:id => :content, &block)
        end
      end.new
      @output = Tilt['erb'].new { '<%= widget.to_html do %><h1>Title</h1><p>Content</p><% end %>' }.render(self, :widget => widget)
    end

    it { output.should have_css 'div#content', :count => 1 }
    it { output.should have_css 'div#content > h1', :text => "Title", :count => 1 }
    it { output.should have_css 'div#content > p', :text => "Content", :count => 1 }
  end

  describe 'widget with no content overriden' do
    it 'should raise not implemented' do
      lambda do
        Class.new(Tiny::Widget).new.to_html
      end.should raise_error(NotImplementedError)
    end
  end
end
