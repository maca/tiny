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
        output = tag(:li, :class => [], :id => nil)
        output.should == "<li></li>"
      end

      it 'should not emit value for an atribute value of true' do
        output = tag(:li, 'data-something' => true)
        output.should == "<li data-something></li>"
      end

      it 'should not allow passing text without #text' do
        output = tag(:li) { 'Hello' }
        output.should == '<li></li>'
      end

      it 'should output multiple classes passing an array' do
        output = tag(:li, :class => %w(item in-stock))
        output.should == '<li class="item in-stock"></li>'
      end

      it 'should allow passing content as string' do
        tag(:h1, "Hello").should == "<h1>Hello</h1>"
        tag(:h1, "Hello", :class => 'main').should == %{<h1 class="main">Hello</h1>} 
      end

      describe 'safety' do
        it 'should escape attribute html' do
          tag(:a, :href => '<script>').should == '<a href="&lt;script&gt;"></a>'
          tag(:a, :href => 'art&copy').should == '<a href="art&amp;copy"></a>'
        end

        it 'should allow html in attribute' do
          tag(:a, :href => raw('<script>')).should == '<a href="<script>"></a>'
        end
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
        it 'should not buffer contiguous tags' do
          tag(:span)
          tag(:a).should == '<a></a>'
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
      it 'should buffer with newlines and indentation' do
        output = tag(:ul) do
          tag (:li)
        end
        output.should == "<ul>\n  <li></li>\n</ul>"
      end

      it 'should buffer with newlines after text' do
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

  describe 'special nodes' do
    describe 'comments' do
      it 'should emit comment' do
        comment('Hello').should == "<!-- Hello -->\n"
        comment('Hello -- world').should == "<!-- Hello - - world -->\n"
        comment('Hello -- -- world').should == "<!-- Hello - - - - world -->\n"
      end

      it 'should buffer comments' do
        tag(:div) do
          comment 'foo'
          comment 'bar'
        end.should == "<div>\n  <!-- foo -->\n  <!-- bar -->\n</div>"
      end
    end

    describe 'cdata' do
      it 'should emit cdata' do
        cdata('Hello').should == "<![CDATA[Hello]]>\n"
      end

      it 'should buffer cdata' do
        tag(:div) do
          cdata('foo')
          cdata('bar')
        end.should == "<div>\n  <![CDATA[foo]]>\n  <![CDATA[bar]]>\n</div>"
      end

      it 'should not "escape" cdata terminator' do
        cdata(']]>').should == "<![CDATA[]]]]><![CDATA[>]]>\n"
      end
    end

    describe 'doctype' do
      it 'should emit html5 doctype' do
        doctype.should == '<!DOCTYPE html>'
      end
    end
  end

  describe 'tag closing' do
    describe 'void tags' do
      it 'should define void tags' do
        Tiny::HTMLTags.void_tags.should == %w(area base br col hr img input link meta param embed)
      end

      Tiny::HTMLTags.void_tags.each do |tag_name|
        describe tag_name do
          it 'sould autoclose' do
            tag(tag_name).should == "<#{tag_name} />"
          end

          it 'should omit content' do
            tag(tag_name){ text 'hi' }.should == "<#{tag_name} />"
          end
        end
      end
    end

    describe 'content tags' do
      it 'should define content tags' do
        tags  = %w(
          article aside audio bdi canvas command datalist details
          figcaption figure header hgroup keygen mark meter nav output progress
          section source summary track video wbr a abbr address b bdo big
          blockquote body button caption cite code colgroup dd del dfn div dl dt
          em fieldset footer form h1 h2 h3 h4 h5 h6 head html i iframe ins kbd
          label legend li map noscript object ol optgroup option p pre q rp rt
          ruby s samp script select small span strike strong style sub sup table
          tbody td textarea tfoot th thead time title tr tt u ul var
        )
        Tiny::HTMLTags.content_tags.should == tags
      end

      Tiny::HTMLTags.content_tags.each do |tag_name|
        it "should not autoclose #{tag_name} if not empty" do
          tag(tag_name).should == "<#{tag_name}></#{tag_name}>"
        end
      end
    end
  end

  describe 'markup' do
    before do
      @output = markup do
        tag(:head) { tag(:title, "Tiny Page!") }
        tag(:body) { tag(:h1, "Hello Tiny!") }
      end
    end

    it { output.should have_css 'head', :count => 1 }
    it { output.should have_css 'head > title', :text => "Tiny Page!", :count => 1 }
    it { output.should have_css 'body', :count => 1 }
    it { output.should have_css 'body > h1', :text => "Hello Tiny!", :count => 1 }
  end

  describe 'dsl' do
    include Tiny::HTMLTags

    describe 'void tags' do
      Tiny::HTMLTags.void_tags.each do |tag_name|
        it "should render '#{tag_name}'" do
          self.send(tag_name).should == "<#{tag_name} />"
        end
      end

      it "should render attributes" do
        link(:href => "some.css").should == '<link href="some.css" />'
      end
    end

    describe 'content tags' do
      Tiny::HTMLTags.content_tags.each do |tag_name|
        it "should render '#{tag_name}'" do
          self.send(tag_name).should == "<#{tag_name}></#{tag_name}>"
        end
      end
      
      it "should render content and attributes" do
        h1(:class => 'main') { text "Hello" }.should == %{<h1 class="main">\n  Hello\n</h1>} 
        h1("Hello", :class => 'main').should == %{<h1 class="main">Hello</h1>} 
      end
    end
  end
end
