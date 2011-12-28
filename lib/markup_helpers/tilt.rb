module Tilt
  class Template
    def render scope = Object.new, locals = {}, &block
      scope.instance_variable_set :@__tilt_context, self
      output = evaluate scope, locals || {}, &block
      if scope.instance_variable_get :@__tilt_context
        scope.send :remove_instance_variable, :@__tilt_context
      end
      output
    end
  end
end

module MarkupHelpers
  module TiltHelpers
    def capture &block
      case @__tilt_context
      when Tilt::ErubisTemplate, Tilt::ERBTemplate
        erb_capture &block
      when Tilt::HamlTemplate
        capture_haml &block
      else
        yield
      end
    end

    def concat content
      case @__tilt_context
      when Tilt::ErubisTemplate, Tilt::ERBTemplate
        erb_buffer << content
      when Tilt::HamlTemplate
        haml_concat content
      else
        content
      end
    end
  end

  include TiltHelpers
end
