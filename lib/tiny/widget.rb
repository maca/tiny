module Tiny
  class Widget
    include HTML
    include Tiny::Helpers

    def content
      raise NotImplementedError
    end

    def render &block
      markup do
        next content unless block_given?
        content do
          context = eval('self', block.binding)
          text! context.instance_eval{ markup(&block) } 
        end
      end
    end
    alias to_html render
  end
end
