require 'spec_helper'

describe 'markup helpers' do
  it "should register tiny erubis templates for '.erubis' files" do
    expect(Tilt['erubis']).to eq(Tiny::Erubis::ErubisTemplate)
    expect(Tilt['erb']).to eq(Tiny::Erubis::ErubisTemplate)
  end

  it 'should default to tiny erubis engine' do
    engine = Tilt['erb'].new{}.instance_variable_get(:@engine)
    expect(engine).to be_a Tiny::Erubis::Eruby
  end

  it 'should use tiny escaped erubis engine for escaping html' do
    engine = Tilt['erb'].new(nil, escape_html: true){}.instance_variable_get(:@engine)
    expect(engine).to be_a Tiny::Erubis::EscapedEruby
  end

  it 'should escape html when passing :escape_html => true option' do
    template = Tilt['erb'].new(nil, escape_html: true) { %(<%= "<p>Hello World!</p>" %>) }
    expect(template.render).to eq("&lt;p&gt;Hello World!&lt;/p&gt;")
  end

  it 'should not escape htmle when passing :escape_html => false option' do
    template = Tilt['erb'].new(nil, escape_html: false) { %(<%= "<p>Hello World!</p>" %>) }
    expect(template.render).to eq("<p>Hello World!</p>")
  end

  it 'should allow block with explicit output' do
    template = Tilt['erb'].new do
      <<-ERB
      <%= [1,2].each do |i| %>
      <% end %>
      ERB
    end
    expect(template.render).to include "[1, 2]"
  end

  it 'should allow block with explicit output' do
    template = Tilt['erb'].new nil, escape_html: true do
      <<-ERB
      <%= [1,2].each do |i| %>
      <% end %>
      ERB
    end
    expect(template.render).to include "[1, 2]"
  end
end
