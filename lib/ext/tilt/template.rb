module Tilt
  class Template
    alias :__render :render

    def render scope = Object.new, locals = {}, &block
      scope.instance_variable_set :@__tilt_context, self
      output = __render scope, locals, &block
      scope.send :remove_instance_variable, :@__tilt_context
      output
    end
  end
end

