# Mark invalid form controls with aria-invalid instead of wrapping them in a
# <div class="field_with_errors">, so styling stays in the `field` utility.
# Text-like fields also get their message right below them, linked with aria-describedby
# (kept alongside any hint). Radios and checkboxes rely on the summary at the top of the form.
ActiveSupport.on_load(:action_view) do
  ActionView::Base.field_error_proc = proc do |html_tag, instance|
    fragment = Nokogiri::HTML5::DocumentFragment.parse(html_tag)
    field = fragment.at_css("input:not([type=hidden]), textarea, select")
    next html_tag unless field

    field["aria-invalid"] = "true"

    # Tags::Base has no public reader for the attribute name.
    attribute = instance.instance_variable_get(:@method_name)
    messages = instance.object.respond_to?(:errors) ? instance.object.errors.full_messages_for(attribute) : []

    if field["id"] && messages.any? && !field["type"].in?(%w[ radio checkbox ])
      error_id = "#{field["id"]}_error"
      field["aria-describedby"] = [ field["aria-describedby"], error_id ].compact.join(" ")
      field.add_next_sibling(content_tag(:p, messages.to_sentence, id: error_id, class: "field-error"))
    end

    fragment.to_html.html_safe
  end
end
