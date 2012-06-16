# encoding: utf-8
require 'spec_helper'

describe 'markup helpers' do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe 'tag' do
    describe 'basic' do
      before do
        @output = Tilt['erb'].new { '<%= tag(:li, "Hello") %>' }.render(self)
      end
      it { output.should have_css 'li', :text => "Hello" }
    end

    describe 'shallow blocks' do
      before do
        @output = Tilt['erb'].new do 
          <<-ERB
            <% tag(:li) do %>
              <%= tag(:a, 'Hello') %>
            <% end %>
          ERB
        end.render(self).tap { |e| puts e }
      end
      it { output.should have_css 'li' }
      it { output.should have_css 'li > a', :text => 'Hello' }
    end

    describe 'deeper blocks' do
      before do
        @output = Tilt['erb'].new do 
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
  end
end
