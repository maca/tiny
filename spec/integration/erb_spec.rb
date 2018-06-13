# encoding: utf-8
require 'spec_helper'

describe 'markup helpers', type: :request do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  def span(&block)
    with_buffer do
      tag(:span, &block)
    end
  end

  def check_block(&block)
    expect(erb_block?(block)).to be_truthy
  end

  it 'should determine block origin' do
    Tilt['erb'].new { '<% check_block do %><% end  %>' }.render(self)
  end

  it 'should capture erb' do
    Tilt['erb'].new { '<% mk = with_buffer("Tiny!") do |s| %>Hello <%= s %><% end %><%- expect(mk).to eq "Hello Tiny!" %>' }.render(self)
  end

  it 'should emit tag' do
    @output = Tilt['erb'].new { '<%= tag(:div) %>' }.render(self)
    expect(output).to have_css 'div', count: 1
  end

  it 'should not buffer multiple tags' do
    template = Tilt['erb'].new { '<%= yield %>' }
    output   = template.render(self) { tag(:span); tag(:a) }
    expect(output).to eq('<a></a>')
  end

  it 'should buffer multiple tags inside with_buffer block' do
    template = Tilt['erb'].new { '<%= yield %>' }
    output   = template.render(self) { with_buffer { tag(:span); tag(:a) }  }
    expect(output).to eq("<span></span>\n<a></a>\n")
  end

  it 'should concat erb block' do
    template = Tilt['erb'].new(outvar: '@_out_buf') { '<%= span do %>Hello<% end %>' }
    expect(template.render(self)).to eq("<span>\n  Hello\n</span>\n")
  end

  describe 'block passing' do
    describe 'shallow' do
      before do
        @output = Tilt['erb'].new(outvar: '@_out_buf') do
          <<-ERB
            <%= tag(:div) do %>
              <%= tag(:a) do %>
                Hello
              <% end %>
            <% end %>
          ERB
        end.render(self)
      end
      it { expect(output).to have_css 'div',     count: 1 }
      it { expect(output).to have_css 'a',       count: 1 }
      it { expect(output).to have_css 'div > a', text: 'Hello' }
    end

    describe 'nested' do
      before do
        @output = Renderer.new('erb_list.erb').render
      end
      it_should_behave_like 'it renders my list'
    end
  end

  describe 'with helpers' do
    before do
      @output = Renderer.new('erb_list_with_helpers.erb').render
    end
    it_should_behave_like 'it renders my list'
  end
end
