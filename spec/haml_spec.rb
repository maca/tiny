# encoding: utf-8
require 'spec_helper'

describe 'markup helpers' do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe 'tag' do
    describe 'basic' do
      it 'should emit tag' do
        @output = Tilt['haml'].new { '= tag(:div)' }.render(self)
        output.should have_css 'div'
      end

      it 'should emit haml block' do
        @output = Tilt['haml'].new do
          <<-HAML
= tag(:div) do
  Hello
          HAML
        end.render(self)
        output.should have_css 'div', :text => "Hello"
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
        it { output.should have_css 'div' }
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
      Hey
      = tag(:span) do
        Ho
            HAML
          end.render(self)
        end
        it { output.should have_css 'ul' }
        it { output.should have_css 'ul > li' }
        it { output.should have_css 'ul > li > a' }
        it { output.should have_css 'ul > li > a', :text => 'Hey' }
        it { output.should have_css 'ul > li > a > span', :text => 'Ho' }
      end
    end
  end
end
