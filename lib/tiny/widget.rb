module Tiny
  class Widget
    include HTMLTags
    include Tiny::Helpers

    def content
      raise NotImplementedError
    end

    def render &block
      markup do
        next content unless block_given?
        content do
          context = eval('self', block.binding)
          text! context.instance_eval{ tiny_capture(&block) } 
        end
      end
    end
    alias to_html render
  end
end
