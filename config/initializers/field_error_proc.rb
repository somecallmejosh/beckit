# Mark invalid form controls with aria-invalid instead of wrapping them in a
# <div class="field_with_errors">, so styling stays in the `field` utility.
ActiveSupport.on_load(:action_view) do
  ActionView::Base.field_error_proc = proc do |html_tag, _instance|
    html_tag.to_str.sub(/\A<(input|textarea|select)\b/, '<\1 aria-invalid="true"').html_safe
  end
end
