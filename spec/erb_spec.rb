# encoding: utf-8
require 'spec_helper'
require 'erubis'

describe 'markup helpers' do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe 'tag' do
    it 'should emit tag' do
      @output = Tilt['erb'].new(:outvar => '@_out_buf') do
        '<%= tag(:div) %>'
      end.render(self)
      output.should have_css 'div', :count => 1
    end
  end

  describe 'block passing' do
    describe 'shallow' do
      before do
        @output = Tilt['erb'].new(:outvar => '@_out_buf') do 
          <<-ERB
            <% tag(:div) do %>
              <% tag(:a) do %>
                Hello
              <% end %>
            <% end %>
          ERB
        end.render(self)
      end
      it { output.should have_css 'div',     :count => 1 }
      it { output.should have_css 'a',       :count => 1 }
      it { output.should have_css 'div > a', :text => 'Hello' }
    end

    it 'should pass widget to block' do
      @output = Tilt['erb'].new(:outvar => '@_out_buf') do 
        <<-ERB
            <% tag(:div) do |div| %>
              <% div.should be_a Tiny::Widget %>
              <% tag(:a) do |a| %>
                <% a.tag_name.should == :a %>
              <% end %>
            <% end %>
        ERB
      end.render(self)
    end

    describe 'nested' do
      before do
        @output = Tilt['erb'].new(:outvar => '@_out_buf') do 
          <<-ERB
            <% tag(:ul) do %>
              <% tag(:li) do %>
                <% tag(:a) do %>
                  A
                  <% tag(:span) do %>
                    1
                  <% end %>
                <% end %>
              <% end %>
              <% tag(:li) do %>
                <% tag(:a) do %>
                  B
                  <% tag(:span) do %>
                    2
                  <% end %>
                <% end %>
              <% end %>
              <% tag(:li) do %>
                <% tag(:a) do %>
                  C
                  <% tag(:span) do %>
                    3
                  <% end %>
                <% end %>
              <% end %>
            <% end %>
          ERB
        end.render(self)
      end
      
      it { output.should have_css 'ul',    :count => 1 }
      it { output.should have_css 'li',    :count => 3 }
      it { output.should have_css 'a',     :count => 3 }
      it { output.should have_css 'span',  :count => 3 }
      it { output.should have_css 'ul > li' }
      it { output.should have_css 'ul > li > a' }
      it { output.should have_css 'ul > li > a', :text => 'A' }
      it { output.should have_css 'ul > li > a > span', :text => '1' }
      it { output.should have_css 'ul > li > a', :text => 'B' }
      it { output.should have_css 'ul > li > a > span', :text => '2' }
      it { output.should have_css 'ul > li > a', :text => 'C' }
      it { output.should have_css 'ul > li > a > span', :text => '3' }
    end
  end
  
  describe 'formatting' do
    it 'shuould concat with newlines and indentation' do
      output = Tilt['erb'].new(:outvar => '@_out_buf') do 
        <<-ERB
<% tag(:ul) do %>
  <%= tag(:li) %>
<% end %>
        ERB
      end.render(self)
      output.should == "<ul>\n  <li></li>\n</ul>"
    end
  end
end
