# encoding: utf-8
require 'spec_helper'

describe 'markup helpers', type: :request do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  describe 'tag' do
    it 'should emit tag' do
      @output = Tilt['haml'].new { '= tag(:div)' }.render(self)
      expect(output).to have_css 'div', count: 1
    end

    it 'should emit haml block' do
      @output = Tilt['haml'].new do
        <<-HAML
= tag(:div) do
  Hello
        HAML
      end.render(self)
      expect(output).to have_css 'div', text: "Hello", count: 1
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
      it { expect(output).to have_css 'div',     count: 1 }
      it { expect(output).to have_css 'a',       count: 1 }
      it { expect(output).to have_css 'div > a', text: 'Hello' }
    end

    describe 'nested' do
      before do
        @output = Tilt.new("#{FIXTURES}/haml_list.haml").render(self)
      end

      it_should_behave_like 'it renders my list'
    end
  end

  describe 'with helpers' do
    before do
      @output = Renderer.new('haml_list_with_helpers.haml').render
    end
    it_should_behave_like 'it renders my list'
  end
end
