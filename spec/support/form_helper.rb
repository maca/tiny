module FormHelper
  class MyForm < Tiny::Widget
    def initialize(action)
      @action = action
    end

    def markup
      form(action: @action) do
        fieldset do
          yield(self)
        end
      end
    end

    def text_input(name, value)
      TextInput.new(name, value).to_html
    end
  end

  class TextInput < Tiny::Widget
    def initialize(name, value)
      @name, @value = name, value
    end

    def markup
      label(@name.capitalize, for: @name)
      input(type: 'text', id: @name, name: @name, value: @value)
    end
  end

  def my_form(action, &block)
    MyForm.new(action).to_html(&block)
  end
end
