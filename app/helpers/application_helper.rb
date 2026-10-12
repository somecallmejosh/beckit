module ApplicationHelper
  # Heroicons Micro (16x16, solid).
  ICON_PATHS = {
    arrow_left: "M14 8a.75.75 0 0 1-.75.75H4.56l3.22 3.22a.75.75 0 1 1-1.06 1.06l-4.5-4.5a.75.75 0 0 1 0-1.06l4.5-4.5a.75.75 0 0 1 1.06 1.06L4.56 7.25h8.69A.75.75 0 0 1 14 8Z",
    check: "M12.416 3.376a.75.75 0 0 1 .208 1.04l-5 7.5a.75.75 0 0 1-1.154.114l-3-3a.75.75 0 0 1 1.06-1.06l2.353 2.353 4.493-6.74a.75.75 0 0 1 1.04-.207Z",
    bars_3: "M2 3.75A.75.75 0 0 1 2.75 3h10.5a.75.75 0 0 1 0 1.5H2.75A.75.75 0 0 1 2 3.75ZM2 8a.75.75 0 0 1 .75-.75h10.5a.75.75 0 0 1 0 1.5H2.75A.75.75 0 0 1 2 8Zm0 4.25a.75.75 0 0 1 .75-.75h10.5a.75.75 0 0 1 0 1.5H2.75a.75.75 0 0 1-.75-.75Z",
    x_mark: "M5.28 4.22a.75.75 0 0 0-1.06 1.06L6.94 8l-2.72 2.72a.75.75 0 1 0 1.06 1.06L8 9.06l2.72 2.72a.75.75 0 1 0 1.06-1.06L9.06 8l2.72-2.72a.75.75 0 0 0-1.06-1.06L8 6.94 5.28 4.22Z",
    plus: "M8.75 3.75a.75.75 0 0 0-1.5 0v3.5h-3.5a.75.75 0 0 0 0 1.5h3.5v3.5a.75.75 0 0 0 1.5 0v-3.5h3.5a.75.75 0 0 0 0-1.5h-3.5v-3.5Z"
  }.freeze

  def icon(name, css = nil)
    tag.svg(viewBox: "0 0 16 16", class: [ "size-4 shrink-0 fill-current", css ], aria: { hidden: true }) do
      tag.path(d: ICON_PATHS.fetch(name), "fill-rule": "evenodd", "clip-rule": "evenodd")
    end
  end

  # Heading for the journal: time of day in the user's zone, or a birthday wish.
  def greeting_for(user, now = Time.current)
    return "Happy birthday, #{user.first_name}" if user.birthday_today?(now.to_date)

    salutation = case now.hour
    when 5...12 then "Good morning"
    when 12...17 then "Good afternoon"
    when 17...22 then "Good evening"
    else "Hello"
    end
    "#{salutation}, #{user.first_name}"
  end

  def nav_link_to(name, path, active:, **options)
    classes = "rounded-full text-base/6 font-medium sm:text-sm/6 " +
      (active ? "bg-stone-950/5 text-stone-900 dark:bg-white/10 dark:text-white" : "text-stone-600 hover:bg-stone-950/5 hover:text-stone-900 dark:text-stone-400 dark:hover:bg-white/5 dark:hover:text-white")
    link_to name, path, class: [ classes, options.delete(:class) ], aria: { current: (active ? "page" : nil) }, **options
  end

  # Self-hosted wordmark (no third-party request), with a light-on-dark variant.
  def logo_tag(css = "h-7 w-auto")
    safe_join([
      image_tag("logo.svg", alt: "beckit", class: [ css, "dark:hidden" ]),
      image_tag("logo-dark.svg", alt: "beckit", class: [ css, "not-dark:hidden" ])
    ])
  end
end
