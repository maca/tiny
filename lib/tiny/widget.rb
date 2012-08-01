module Tiny
  class Widget
    include HTMLTags
    include Tiny::Helpers

    def content
      raise NotImplementedError
    end

    def render &block
      markup do
        content &block 
      end
    end
  end
end
