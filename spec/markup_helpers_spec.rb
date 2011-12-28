# encoding: utf-8
require 'spec_helper'

describe 'markup helpers' do
  include MarkupHelpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe 'tag' do
    describe 'basic' do
      describe 'attributes and content' do
        before do
          @output = tag(:li, "Hello", :class => 'item', :id => 'hello') 
        end
        it { output.should have_css 'li' }
        it { output.should have_css 'li', :text => "Hello" }
        it { output.should have_css 'li.item' }
        it { output.should have_css 'li#hello' }
      end

      describe 'blank attribute values' do
        before do
          @output = tag(:li, "Hello", :class => [], :id => nil) 
        end
        it { @output.should == '<li>Hello</li>'}
      end

      describe 'true attribute' do
        before do
          @output = tag(:li, "Hello", 'data-something' => true) 
        end
        it { @output.should == '<li data-something>Hello</li>'}
      end

      describe 'multiple classes' do
        before do
          @output = tag(:li, "Hello", :class => %w(item in-stock)) 
        end
        it { output.should have_css 'li.item' }
        it { output.should have_css 'li.in-stock' }
      end

      describe 'in erb' do
        before do
          @output = Tilt['erb'].new { '<%= tag(:li, "Hello") %>' }.render(self)
        end
        it { output.should have_css 'li', :text => "Hello" }
      end

      describe 'in haml' do
        before do
          @output = Tilt['haml'].new { '= tag(:li, "Hello")' }.render(self)
        end
        it { output.should have_css 'li', :text => "Hello" }
      end
    end

    describe 'shallow blocks' do
      describe 'in ruby' do
        before do
          @output = tag(:li) { tag(:a, 'Hello') }
        end
        it { output.should have_css 'li' }
        it { output.should have_css 'li > a', :text => 'Hello' }
      end

      describe 'in erb' do
        before do
          @output = Tilt['erb'].new(:outvar => '@_out_buf') do 
            <<-ERB
            <% tag(:li) do %>
              <%= tag(:a, 'Hello') %>
            <% end %>
            ERB
          end.render(self)
        end
        it { output.should have_css 'li' }
        it { output.should have_css 'li > a', :text => 'Hello' }
      end

      describe 'in haml' do
        before do
          @output = Tilt['haml'].new(:outvar => '@_out_buf') do 
            <<-ERB
- tag(:li) do
  = tag(:a, 'Hello')
            ERB
          end.render(self)
        end
        it { output.should have_css 'li' }
        it { output.should have_css 'li > a', :text => 'Hello' }
      end
    end

    describe 'deeper blocks' do
      describe 'in ruby' do
        before do
          @output = tag(:li) { tag(:a, 'Hello') { tag(:img) } }
        end
        it { output.should have_css 'li' }
        it { output.should have_css 'li > a' }
        it { output.should have_css 'li > a > img' }
      end

      describe 'in erb' do
        before do
          @output = Tilt['erb'].new(:outvar => '@_out_buf') do 
            <<-ERB
            <% tag(:li) do %>
              <% tag(:a, 'Hello') do %>
                <%= tag(:img) %>
              <% end %>
            <% end %>
            ERB
          end.render(self)
        end
        it { output.should have_css 'li' }
        it { output.should have_css 'li > a' }
        it { output.should have_css 'li > a > img' }
      end

      describe 'in haml' do
        before do
          @output = Tilt['haml'].new(:outvar => '@_out_buf') do 
            <<-ERB
- tag(:li) do
  - tag(:a, 'Hello') do
    = tag(:img)
            ERB
          end.render(self)
        end
        it { output.should have_css 'li' }
        it { output.should have_css 'li > a' }
        it { output.should have_css 'li > a > img' }
      end
    end
  end
end
