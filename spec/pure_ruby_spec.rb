# encoding: utf-8
require 'spec_helper'

describe 'markup helpers' do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe 'tag' do
    describe 'basic' do
      describe 'attributes and content' do
        before do
          @output = tag(:li, :class => 'item', :id => 'hello') { text 'Hello' }
        end
        it { output.should have_css 'li', :count => 1 }
        it { output.should have_css 'li', :text => "Hello" }
        it { output.should have_css 'li.item' }
        it { output.should have_css 'li#hello' }
      end

      it 'should not use blank attribute values' do
        output = tag(:li, :class => [], :id => nil) { text 'Hello' }
        output.should =~ /<li>/
      end

      it 'should not emit value for an atribute value of true' do
        output = tag(:li, 'data-something' => true)
        output.should == "<li data-something />"
      end


      it 'should not allow passing text without #text' do
        output = tag(:li) { 'Hello' }
        output.should == '<li></li>'
      end

      describe 'multiple classes' do
        before do
          @output = tag(:li, :class => %w(item in-stock)) { text 'Hello' }
        end
        it { output.should have_css 'li.item' }
        it { output.should have_css 'li.in-stock' }
      end
    end

    describe 'blocks' do
      describe 'shallow blocks' do
        before do
          @output = tag(:div) { tag(:a) { text 'Hello' } }
        end
        it { output.should have_css 'div', :count => 1 }
        it { output.should have_css 'a',   :count => 1 }
        it { output.should have_css 'div > a', :text => 'Hello' }
      end

      describe 'deeper blocks' do
        before do
          @output = tag(:div) do 
            tag(:a) do
              text 'Hello'
              tag(:img)
            end
          end
        end
        it { output.should have_css 'div',     :count => 1 }
        it { output.should have_css 'a',       :count => 1 }
        it { output.should have_css 'div > a' }
        it { output.should have_css 'div > a', :text => 'Hello' }
        it { output.should have_css 'img',     :count => 1 }
        it { output.should have_css 'div > a > img' }
      end
    end

    describe 'buffering' do
      describe 'tag concatenation' do
        before do
          @output = tag(:ul) do
            tag(:li)
            tag(:li)
            tag(:li)
          end
        end

        it { output.should have_css 'ul',      :count => 1 }
        it { output.should have_css 'li',      :count => 3 }
        it { output.should have_css 'ul > li', :count => 3 }
      end

      describe 'concatenation with text' do
        before do
          @output = tag(:ul) do
            tag(:li) { text 'One' }
            tag(:li) { text 'Two' }
            tag(:li) { text 'Three' }
          end
        end

        it { output.should have_css 'ul',      :count => 1 }
        it { output.should have_css 'li',      :count => 3 }
        it { output.should have_css 'ul > li', :count => 3 }
        it { output.should have_css 'ul > li', :text => 'One' }
        it { output.should have_css 'ul > li', :text => 'Two' }
        it { output.should have_css 'ul > li', :text => 'Three' }
      end

      describe 'nested' do
        before do
          @output = tag(:ul) do
            tag(:li) { tag(:a) { text 'One' } }
            tag(:li) { tag(:a) { text 'Two' } }
            tag(:li) { tag(:a) { text 'Three' } }
          end
        end

        it { output.should have_css 'ul',          :count => 1 }
        it { output.should have_css 'li',          :count => 3 }
        it { output.should have_css 'ul > li',     :count => 3 }
        it { output.should have_css 'a',           :count => 3 }
        it { output.should have_css 'ul > li > a', :text => 'One' }
        it { output.should have_css 'ul > li > a', :text => 'Two' }
        it { output.should have_css 'ul > li > a', :text => 'Three' }
      end
      
      describe 'outside content block' do
        it 'should not concatenate contigous calls' do
          tag(:ul)
          tag(:div).should == '<div />'
        end
      end
    end

    describe 'text' do
      it 'should escape text' do
        @output = tag(:li){ text '&<>' }
        @output.should =~ /&amp;&lt;&gt;/
      end

      it 'should allow not scaped text' do
        @output = tag(:li){ text! '&<>' }
        @output.should =~ /&<>/
      end
    end

    describe 'formatting' do
      it 'shuould concat with newlines and indentation' do
        output = tag(:ul) do
          tag (:li)
        end
        output.should == "<ul>\n  <li />\n</ul>"
      end

      it 'shuould concat with newlines after text' do
        output = tag(:ul) do
          tag (:li) do
            text 'Hi'
            text! 'Hi'
          end
        end
        output.should == "<ul>\n  <li>\n    Hi\n    Hi\n  </li>\n</ul>"
      end
    end
  end
end
