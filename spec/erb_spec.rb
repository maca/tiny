# encoding: utf-8
require 'spec_helper'

describe 'markup helpers' do
  include Tiny::Helpers

  let(:output) do
    Capybara::Node::Simple.new(@output)
  end

  def span &block
    markup do
      tag(:span, &block)
    end
  end

  def check_block &block
    erb_block?(block).should be_true
  end
 
  it 'should determine block origin' do
    Tilt['erb'].new { '<% check_block do %><% end  %>' }.render(self)
  end

  it 'should capture erb' do
    Tilt['erb'].new { '<% mk = markup do %>Hello<% end %><%- mk.should == "Hello" %>' }.render(self)
  end

  it 'should emit tag' do
    @output = Tilt['erb'].new { '<%= tag(:div) %>' }.render(self)
    output.should have_css 'div', :count => 1
  end

  it 'should not buffer multiple tags' do
    template = Tilt['erb'].new { '<%= yield %>' }
    output   = template.render(self) { tag(:span); tag(:a) }
    output.should == '<a></a>'
  end

  it 'should buffer multiple tags inside markup block' do
    template = Tilt['erb'].new { '<%= yield %>' }
    output   = template.render(self) { markup { tag(:span); tag(:a) }  }
    output.should == '<span></span><a></a>'
  end

  it 'should concat erb block' do
    template = Tilt['erb'].new(:outvar => '@_out_buf') { '<%= span do %>Hello<% end %>' }
    template.render(self).should == "<span>\n  Hello\n</span>"
  end

  describe 'block passing' do
    describe 'shallow' do
      before do
        @output = Tilt['erb'].new(:outvar => '@_out_buf') do 
          <<-ERB
            <%= tag(:div) do %>
              <%= tag(:a) do %>
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
  
  describe 'with helpers' do
    before do
      @output = Renderer.new('erb_list_with_helpers.erb').render
    end
    it_should_behave_like 'it renders my list'
  end
end
