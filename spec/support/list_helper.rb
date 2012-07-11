module ListHelper
  def list nums, &block
    html_tag(:ul) do
      nums.each(&block)
    end.tap { |tag| puts "Tag: #{tag}" }
  end

  def item_content num
    html_tag(:li) do
      html_tag(:a) do
        text (num + 64).chr
        html_tag(:span) { text num }
      end
    end
  end
end
