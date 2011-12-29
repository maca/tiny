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
