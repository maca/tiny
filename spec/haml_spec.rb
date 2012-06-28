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

    it 'should pass widget to block' do
      Tilt['haml'].new do 
        <<-HAML
= tag(:div) do |div|
  - div.should be_a Tiny::Widget 
  = tag(:a) do |a|
    - a.tag_name.should == :a
        HAML
      end.render(self)
    end

    describe 'nested' do
      before do
        @output = Tilt['haml'].new do 
          <<-HAML
= tag(:ul) do
  = tag(:li) do
    = tag(:a) do
      A
      = tag(:span) do
        1
  = tag(:li) do
    = tag(:a) do
      B
      = tag(:span) do
        2
  = tag(:li) do
    = tag(:a) do
      C
      = tag(:span) do
        3
          HAML
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
      output = Tilt['haml'].new do 
        <<-HAML
= tag(:ul) do
  = tag(:li)
        HAML
      end.render(self)
      output.should == "<ul>\n  <li></li>\n</ul>\n"
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
end
