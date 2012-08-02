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
      @output = Tilt['erb'].new(:outvar => '@_out_buf') { '<%= tag(:div) %>' }.render(self)
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

    describe 'nested' do
      before do
        @output = Renderer.new('erb_list.erb').render
      end
      it_should_behave_like 'it renders my list'
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
      output.should == "<ul>\n  <li></li></ul>"
    end
  end

  describe 'with helpers' do
    before do
      @output = Renderer.new('erb_list_with_helpers.erb').render
    end
    it_should_behave_like 'it renders my list'
  end
end
