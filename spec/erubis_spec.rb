require 'spec_helper'

describe 'markup helpers' do
  it "should register tiny erubis templates for '.erubis' files" do
    Tilt['erubis'].should == Tiny::Erubis::ErubisTemplate
    Tilt['erb'].should == Tiny::Erubis::ErubisTemplate
  end

  it 'should default to tiny erubis engine' do
    engine = Tilt['erb'].new{}.instance_variable_get(:@engine)
    engine.should be_a Tiny::Erubis::Eruby
  end

  it 'should use tiny escaped erubis engine for escaping html' do
    engine = Tilt['erb'].new(nil, :escape_html => true){}.instance_variable_get(:@engine)
    engine.should be_a Tiny::Erubis::EscapedEruby
  end

  it 'should escape html when passing :escape_html => true option' do
    template = Tilt['erb'].new(nil, :escape_html => true) { %(<%= "<p>Hello World!</p>" %>) }
    template.render.should == "&lt;p&gt;Hello World!&lt;/p&gt;"
  end

  it 'should not escape htmle when passing :escape_html => false option' do
    template = Tilt['erb'].new(nil, :escape_html => false) { %(<%= "<p>Hello World!</p>" %>) }
    template.render.should == "<p>Hello World!</p>"
  end

  it 'should allow block with explicit output' do
    template = Tilt['erb'].new do
      <<-ERB
      <%= [1,2].each do |i| %>
      <% end %>
      ERB
    end
    template.render.should include "[1, 2]"
  end

  it 'should allow block with explicit output' do
    template = Tilt['erb'].new nil, :escape_html => true do
      <<-ERB
      <%= [1,2].each do |i| %>
      <% end %>
      ERB
    end
    template.render.should include "[1, 2]"
  end
end
