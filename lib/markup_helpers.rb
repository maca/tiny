require "markup_helpers/version"
require "markup_helpers/tilt" if Object.const_defined? :Tilt

module MarkupHelpers
  include Haml::Helpers if const_defined? :Haml

  def tag tag_name, content_or_attrs = {}, attrs = nil, &block
    if attrs.nil? && Hash === content_or_attrs
      attrs   = content_or_attrs 
      content = nil
    else
      attrs ||= {}
      content = content_or_attrs
    end

    attrs = attrs.map do |name, val|
      next if val.nil? || val == []
      val == true ? name : %{#{name}="#{[*val].join(' ')}"}
    end.compact.join(' ')

    attrs   = " #{attrs}" unless attrs.empty?
    if block_given?
      content = respond_to?(:capture) ? capture(&block) : yield 
    end
    output  = %{<#{tag_name}#{attrs}>#{content}</#{tag_name}>}
    block_given? && respond_to?(:concat) ? concat(output) : output
  end

  private
  def erb_capture
    old_buffer = erb_buffer.dup
    erb_buffer.clear and yield
    content = erb_buffer.dup
    erb_buffer.replace(old_buffer) and content
  end

  def erb_buffer
    outvar = @__tilt_context.instance_variable_get(:@outvar)
    outvar or raise('Please pass the outvar option when instantiating the erb template')
    instance_variable_get outvar
  end
end
