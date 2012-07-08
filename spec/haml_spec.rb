# encoding: utf-8
require 'spec_helper'

describe 'markup helpers' do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe 'tag' do
    it 'should emit tag' do
      @output = Tilt['haml'].new { '= tag(:div)' }.render(self)
      output.should have_css 'div', :count => 1
    end

    it 'should emit haml block' do
      @output = Tilt['haml'].new do
        <<-HAML
= tag(:div) do
  Hello
        HAML
      end.render(self)
      output.should have_css 'div', :text => "Hello", :count => 1
    end
  end

  describe 'passing blocks' do
    describe 'shallow' do
      before do
        @output = Tilt['haml'].new do 
          <<-HAML
= tag(:div) do
  = tag(:a) do
    Hello
          HAML
        end.render(self)
      end
      it { output.should have_css 'div',     :count => 1 }
      it { output.should have_css 'a',       :count => 1 }
      it { output.should have_css 'div > a', :text => 'Hello' }
    end

    it 'should pass tag to block' do
      Tilt['haml'].new do 
        <<-HAML
= tag(:div) do |div|
  - div.should be_a Tiny::Tag 
  = tag(:a) do |a|
    - a.tag_name.should == :a
        HAML
      end.render(self)
    end

    describe 'nested' do
      before do
        @output = Tilt.new("#{FIXTURES}/haml_list.haml").render(self)
      end

      it_should_behave_like 'it renders my list'
    end
  end

  describe 'formatting' do
    it 'should concat with newlines and indentation' do
      output = Tilt['haml'].new do 
        <<-HAML
= tag(:ul) do
  = tag(:li)
        HAML
      end.render(self)
      output.should == "<ul>\n  <li />\n</ul>\n"
    end

    it 'shuould concat with newlines after text' do
      output = Tilt['haml'].new do 
        <<-HAML
= tag(:ul) do
  = tag(:li) do
    Hi
    Hi
        HAML
      end.render(self)
      output.should == "<ul>\n  <li>\n    Hi\n    Hi\n  </li>\n</ul>\n"
    end
  end

  describe 'with helpers' do
    before do
      @output = Renderer.new('haml_list_with_helpers.haml').render
      puts @output.inspect
    end
    it_should_behave_like 'it renders my list'
  end
end
