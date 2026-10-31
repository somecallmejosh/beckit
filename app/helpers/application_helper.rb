module ApplicationHelper
  # Heroicons Micro (16x16, solid).
  ICON_PATHS = {
    arrow_left: "M14 8a.75.75 0 0 1-.75.75H4.56l3.22 3.22a.75.75 0 1 1-1.06 1.06l-4.5-4.5a.75.75 0 0 1 0-1.06l4.5-4.5a.75.75 0 0 1 1.06 1.06L4.56 7.25h8.69A.75.75 0 0 1 14 8Z",
    check: "M12.416 3.376a.75.75 0 0 1 .208 1.04l-5 7.5a.75.75 0 0 1-1.154.114l-3-3a.75.75 0 0 1 1.06-1.06l2.353 2.353 4.493-6.74a.75.75 0 0 1 1.04-.207Z",
    bars_3: "M2 3.75A.75.75 0 0 1 2.75 3h10.5a.75.75 0 0 1 0 1.5H2.75A.75.75 0 0 1 2 3.75ZM2 8a.75.75 0 0 1 .75-.75h10.5a.75.75 0 0 1 0 1.5H2.75A.75.75 0 0 1 2 8Zm0 4.25a.75.75 0 0 1 .75-.75h10.5a.75.75 0 0 1 0 1.5H2.75a.75.75 0 0 1-.75-.75Z",
    x_mark: "M5.28 4.22a.75.75 0 0 0-1.06 1.06L6.94 8l-2.72 2.72a.75.75 0 1 0 1.06 1.06L8 9.06l2.72 2.72a.75.75 0 1 0 1.06-1.06L9.06 8l2.72-2.72a.75.75 0 0 0-1.06-1.06L8 6.94 5.28 4.22Z",
    magnifying_glass: "M9.965 11.026a5 5 0 1 1 1.06-1.06l2.755 2.754a.75.75 0 1 1-1.06 1.06l-2.755-2.754ZM10.5 7a3.5 3.5 0 1 1-7 0 3.5 3.5 0 0 1 7 0Z",
    plus: "M8.75 3.75a.75.75 0 0 0-1.5 0v3.5h-3.5a.75.75 0 0 0 0 1.5h3.5v3.5a.75.75 0 0 0 1.5 0v-3.5h3.5a.75.75 0 0 0 0-1.5h-3.5v-3.5Z",
    chevron_down: "M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z"
  }.freeze

  def icon(name, css = nil)
    tag.svg(viewBox: "0 0 16 16", class: [ "size-4 shrink-0 fill-current", css ], aria: { hidden: true }) do
      tag.path(d: ICON_PATHS.fetch(name), "fill-rule": "evenodd", "clip-rule": "evenodd")
    end
  end

  # Heading for the journal: time of day in the user's zone, or a birthday wish.
  def greeting_for(user, now = Time.current)
    return "Happy birthday, #{user.first_name}" if user.birthday_today?(now.to_date)

    salutation = (part = time_of_day(now)) ? "Good #{part}" : "Hello"
    "#{salutation}, #{user.first_name}"
  end

  # :morning, :afternoon or :evening; nil late at night.
  def time_of_day(now = Time.current)
    case now.hour
    when 5...12 then :morning
    when 12...17 then :afternoon
    when 17...22 then :evening
    end
  end

  # Drawing beside the greeting. Late night shares the evening one.
  def greeting_image(now = Time.current, **options)
    image_tag "greetings/#{time_of_day(now) || :evening}.svg", alt: "", width: 1380, height: 920, decoding: "async", **options
  end

  # Footer card. One is picked at random on each render; drawings live in images/be-kind/.
  KIND_WORDS = [
    { image: "hug", heading: "Be kind to yourself",
      body: "A hard thought is not a verdict on who you are. Talk to yourself the way you would talk to a good friend having the same kind of day.",
      alt: "Drawing of a person sitting cross-legged with eyes closed, giving themself a hug, beside a sleeping cat and a mug of tea." },
    { image: "forgive", heading: "Let yourself off the hook",
      body: "Everyone gets things wrong. A mistake is something that happened, not proof of who you are. You can learn from it and still let it go.",
      alt: "Drawing of a person kneeling on a cushion, smiling as they release a paper bird from their open hands." },
    { image: "rest", heading: "Rest is allowed",
      body: "You don't have to earn a break. Resting is part of doing well, not a reward for it.",
      alt: "Drawing of a person lying on a couch with their feet up and a book open on their chest, under a crescent moon." },
    { image: "gratitude", heading: "Notice what went right",
      body: "Before the day ends, name one thing that went okay. It counts, however small it seems.",
      alt: "Drawing of a person at a small table writing in a notebook beside a potted plant." },
    { image: "progress", heading: "You're growing, even when it's slow",
      body: "Progress is quiet. Showing up today matters more than how it went.",
      alt: "Drawing of a person watering a small sprouting plant." },
    { image: "body", heading: "Thank your body",
      body: "Your body carried you through today. A slow breath, a stretch or a glass of water is a way of saying thanks.",
      alt: "Drawing of a person sitting cross-legged on a mat, stretching their arms overhead, with a glass of water nearby." },
    { image: "weather", heading: "Feelings are like weather",
      body: "This one will pass, like the others have. You don't have to fix it. You only have to wait it out kindly.",
      alt: "Drawing of a person standing calmly under an umbrella in light rain." },
    { image: "wins", heading: "Small wins count",
      body: "Got out of bed? Ate something? Answered that message? Those are wins. Give yourself credit for them.",
      alt: "Drawing of a person raising a mug in a happy cheer." },
    { image: "worth", heading: "You deserve your own care",
      body: "Offer yourself the patience and warmth you give everyone else. You're worth looking after too.",
      alt: "Drawing of a person wrapped in a blanket in an armchair, holding a small vase with a flower." },
    { image: "again", heading: "You can always begin again",
      body: "A fresh start doesn't have to wait for tomorrow. You can begin again after lunch, or right now.",
      alt: "Drawing of a person with a backpack walking along a winding path toward a rising sun." }
  ].freeze

  def kind_words
    KIND_WORDS.sample
  end

  def nav_link_to(name, path, active:, **options)
    classes = "rounded-full text-base/6 font-medium sm:text-sm/6 " +
      (active ? "bg-stone-950/5 text-stone-900 dark:bg-white/10 dark:text-white" : "text-stone-600 hover:bg-stone-950/5 hover:text-stone-900 dark:text-stone-400 dark:hover:bg-white/5 dark:hover:text-white")
    link_to name, path, class: [ classes, options.delete(:class) ], aria: { current: (active ? "page" : nil) }, **options
  end

  # Self-hosted wordmark (no third-party request), with a light-on-dark variant.
  # Decorative: every caller wraps it in a link labelled "beckit home".
  def logo_tag(css = "h-7 w-auto")
    safe_join([
      image_tag("logo.svg", alt: "", class: [ css, "dark:hidden" ]),
      image_tag("logo-dark.svg", alt: "", class: [ css, "not-dark:hidden" ])
    ])
  end
end
