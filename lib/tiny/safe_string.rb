module Tiny
  class SafeString < String
    def html_safe?; true end

    def concat string
      return super unless String === string
      super Helpers.sanitize string
    end
  end
end
