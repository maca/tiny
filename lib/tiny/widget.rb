module Tiny
  class Widget
    include HTMLTags
    include Tiny::Helpers

    def content
      raise NotImplementedError
    end

    def render
      markup do
        content
      end
    end
  end
end
