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
          @output = tag(:li, class: 'item', id: 'hello') { text 'Hello' }
        end
        it { expect(output).to have_css 'li', count: 1 }
        it { expect(output).to have_css 'li', text: "Hello" }
        it { expect(output).to have_css 'li.item' }
        it { expect(output).to have_css 'li#hello' }
      end

      it 'should not use blank attribute values' do
        output = tag(:li, class: [], id: nil)
        expect(output).to eq("<li></li>")
      end

      it 'should not emit value for an atribute value of true' do
        output = tag(:li, 'data-something' => true)
        expect(output).to eq("<li data-something></li>")
      end

      it 'should not emit value if value is false' do
        output = tag(:li, 'data-something' => false)
        expect(output).to eq("<li></li>")
      end

      it 'should not allow passing text without #text' do
        output = tag(:li) { 'Hello' }
        expect(output).to eq('<li></li>')
      end

      it 'should output multiple classes passing an array' do
        output = tag(:li, class: %w(item in-stock))
        expect(output).to eq('<li class="item in-stock"></li>')
      end

      it 'should allow passing content as string' do
        expect(tag(:h1, "Hello")).to eq("<h1>Hello</h1>")
        expect(tag(:h1, "Hello", class: 'main')).to eq(%(<h1 class="main">Hello</h1>))
      end

      it 'should escape attribute html' do
        expect(tag(:a, href: '<script>')).to eq('<a href="&lt;script&gt;"></a>')
        expect(tag(:a, href: 'art&copy')).to eq('<a href="art&amp;copy"></a>')
      end
    end

    describe 'blocks' do
      describe 'shallow blocks' do
        before do
          @output = tag(:div) { tag(:a) { text 'Hello' } }
        end
        it { expect(output).to have_css 'div', count: 1 }
        it { expect(output).to have_css 'a',   count: 1 }
        it { expect(output).to have_css 'div > a', text: 'Hello' }
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
        it { expect(output).to have_css 'div',     count: 1 }
        it { expect(output).to have_css 'a',       count: 1 }
        it { expect(output).to have_css 'div > a' }
        it { expect(output).to have_css 'div > a', text: 'Hello' }
        it { expect(output).to have_css 'img',     count: 1 }
        it { expect(output).to have_css 'div > a > img' }
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

        it { expect(output).to have_css 'ul',      count: 1 }
        it { expect(output).to have_css 'li',      count: 3 }
        it { expect(output).to have_css 'ul > li', count: 3 }
      end

      describe 'concatenation with text' do
        before do
          @output = tag(:ul) do
            tag(:li) { text 'One' }
            tag(:li) { text 'Two' }
            tag(:li) { text 'Three' }
          end
        end

        it { expect(output).to have_css 'ul',      count: 1 }
        it { expect(output).to have_css 'li',      count: 3 }
        it { expect(output).to have_css 'ul > li', count: 3 }
        it { expect(output).to have_css 'ul > li', text: 'One' }
        it { expect(output).to have_css 'ul > li', text: 'Two' }
        it { expect(output).to have_css 'ul > li', text: 'Three' }
      end

      describe 'nested' do
        before do
          @output = tag(:ul) do
            tag(:li) { tag(:a) { text 'One' } }
            tag(:li) { tag(:a) { text 'Two' } }
            tag(:li) { tag(:a) { text 'Three' } }
          end
        end

        it { expect(output).to have_css 'ul',          count: 1 }
        it { expect(output).to have_css 'li',          count: 3 }
        it { expect(output).to have_css 'ul > li',     count: 3 }
        it { expect(output).to have_css 'a',           count: 3 }
        it { expect(output).to have_css 'ul > li > a', text: 'One' }
        it { expect(output).to have_css 'ul > li > a', text: 'Two' }
        it { expect(output).to have_css 'ul > li > a', text: 'Three' }
      end

      describe 'outside content block' do
        it 'should not buffer contiguous tags' do
          tag(:span)
          expect(tag(:a)).to eq('<a></a>')
        end
      end
    end

    describe 'text' do
      it 'should escape text' do
        @output = tag(:li){ text '&<>' }
        expect(@output).to match(/&amp;&lt;&gt;/)
      end

      it 'should allow not scaped text' do
        @output = tag(:li){ append! '&<>' }
        expect(@output).to match(/&<>/)
      end
    end

    describe 'formatting' do
      it 'should buffer with newlines and indentation' do
        output = tag(:ul) do
          tag :li
          tag :li
        end
        expect(output).to eq("<ul>\n  <li></li>\n  <li></li>\n</ul>")
      end

      it 'should buffer with newlines after text' do
        output = tag(:ul) do
          tag :li do
            text 'Hi'
            append! 'Hi'
          end
        end
        expect(output).to eq("<ul>\n  <li>\n    Hi\n    Hi\n  </li>\n</ul>")
      end
    end
  end

  describe 'special nodes' do
    describe 'comments' do
      it 'should emit comment' do
        expect(comment('Hello')).to eq("<!-- Hello -->")
        expect(comment('Hello -- world')).to eq("<!-- Hello - - world -->")
        expect(comment('Hello -- -- world')).to eq("<!-- Hello - - - - world -->")
      end

      it 'should buffer comments' do
        expect(tag(:div) do
          comment 'foo'
          comment 'bar'
        end).to eq("<div>\n  <!-- foo -->\n  <!-- bar -->\n</div>")
      end
    end

    describe 'cdata' do
      it 'should emit cdata' do
        expect(cdata('Hello')).to eq("<![CDATA[Hello]]>")
      end

      it 'should buffer cdata' do
        expect(tag(:div) do
          cdata('foo')
          cdata('bar')
        end).to eq("<div>\n  <![CDATA[foo]]>\n  <![CDATA[bar]]>\n</div>")
      end

      it 'should not "escape" cdata terminator' do
        expect(cdata(']]>')).to eq("<![CDATA[]]]]><![CDATA[>]]>")
      end
    end

    describe 'doctype' do
      it 'should emit html5 doctype' do
        expect(doctype).to eq('<!DOCTYPE html>')
      end

      it 'should buffer doctype' do
        output = with_buffer{ doctype and tag(:html) }
        expect(output).to eq("<!DOCTYPE html>\n<html></html>\n")

      end
    end
  end

  describe 'tag closing' do
    describe 'void tags' do
      it 'should define void tags' do
        expect(Tiny::HTML.void_tags).to eq(%w(area base br col hr img input link meta param embed))
      end

      Tiny::HTML.void_tags.each do |tag_name|
        describe tag_name do
          it 'sould autoclose' do
            expect(tag(tag_name)).to eq("<#{tag_name} />")
            expect(tag(tag_name.to_sym)).to eq("<#{tag_name} />")
          end

          it 'should omit content' do
            expect(tag(tag_name){ text 'hi' }).to eq("<#{tag_name} />")
          end
        end
      end
    end

    describe 'content tags' do
      it 'should define content tags' do
        tags = %w(
          article aside audio bdi canvas command datalist details
          figcaption figure header hgroup keygen mark meter nav output progress
          section source summary track video wbr a abbr address b bdo big
          blockquote body button caption cite code colgroup dd del dfn div dl dt
          em fieldset footer form h1 h2 h3 h4 h5 h6 head html i iframe ins kbd
          label legend li map noscript object ol optgroup option p pre q rp rt
          ruby s samp script select small span strike strong style sub sup table
          tbody td textarea tfoot th thead time title tr tt u ul var
        )
        expect(Tiny::HTML.content_tags).to eq(tags)
      end

      Tiny::HTML.content_tags.each do |tag_name|
        it "should not autoclose #{tag_name} if not empty" do
          expect(tag(tag_name)).to eq("<#{tag_name}></#{tag_name}>")
          expect(tag(tag_name.to_sym)).to eq("<#{tag_name}></#{tag_name}>")
        end
      end
    end
  end

  describe 'with_buffer' do
    before do
      @output = with_buffer do
        tag(:head) { tag(:title, "Tiny Page!") }
        tag(:body) { tag(:h1, "Hello Tiny!") }
      end
    end

    it { expect(output).to have_title "Tiny Page!" }
    it { expect(output).to have_css 'body', count: 1 }
    it { expect(output).to have_css 'body > h1', text: "Hello Tiny!", count: 1 }
  end

  describe 'dsl' do
    include Tiny::HTML

    describe 'void tags' do
      Tiny::HTML.void_tags.each do |tag_name|
        it "should render '#{tag_name}'" do
          expect(send(tag_name)).to eq("<#{tag_name} />")
        end
      end

      it "should render attributes" do
        expect(link(href: "some.css")).to eq('<link href="some.css" />')
      end
    end

    describe 'content tags' do
      Tiny::HTML.content_tags.each do |tag_name|
        it "should render '#{tag_name}'" do
          expect(send(tag_name)).to eq("<#{tag_name}></#{tag_name}>")
        end
      end

      it "should render content and attributes" do
        expect(h1(class: 'main') { text "Hello" }).to eq(%(<h1 class="main">\n  Hello\n</h1>))
        expect(h1("Hello", class: 'main')).to eq(%(<h1 class="main">Hello</h1>))
      end
    end
  end
end
