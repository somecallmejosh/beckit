require "test_helper"

class SituationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @situation = situations(:one)
    sign_in_as @user
  end

  test "requires authentication" do
    sign_out
    get situations_url
    assert_redirected_to new_session_url
  end

  test "should get index with only the current user's situations" do
    get situations_url
    assert_response :success
    assert_match situations(:one).title, response.body
    assert_no_match situations(:two).title, response.body
  end

  test "should get new" do
    get new_situation_url
    assert_response :success
  end

  test "should create situation for the current user" do
    assert_difference("@user.situations.count") do
      post situations_url, params: { situation: { thought_imagery: "They'll see I'm a fraud", date: Time.current, distortion_ids: [ distortions(:catastrophizing).id, distortions(:mind_reading).id ], emotion_level: 3, user_id: users(:two).id } }
    end

    assert_equal @user, Situation.last.user
    assert_equal 2, Situation.last.distortions.count
    assert_redirected_to situation_url(Situation.last)
  end

  test "should not create invalid situation" do
    assert_no_difference("Situation.count") do
      post situations_url, params: { situation: { title: "", date: Time.current, emotion_level: 11 } }
    end

    assert_response :unprocessable_content
  end

  test "should show situation" do
    get situation_url(@situation)
    assert_response :success
  end

  test "should not show another user's situation" do
    get situation_url(situations(:two))
    assert_response :not_found
  end

  test "each step of an entry has its own page" do
    Situation::STEPS.each do |step|
      get situation_step_url(@situation, step)
      assert_response :success
    end
  end

  test "an unknown step, or another user's entry, is not found" do
    get situation_step_url(@situation, "nope")
    assert_response :not_found

    get situation_step_url(situations(:two), "what-happened")
    assert_response :not_found
  end

  test "saving a step goes to the step its button names, or to the entry" do
    patch situation_step_url(@situation, "what-happened"), params: { situation: { title: "Updated" }, go_to: "name-the-pattern" }
    assert_redirected_to situation_step_url(@situation, "name-the-pattern")
    assert_equal "Updated", @situation.reload.title

    patch situation_step_url(@situation, "whats-on-your-mind"), params: { situation: { emotion_level: 4 } }
    assert_redirected_to situation_url(@situation)
    assert_equal 4, @situation.reload.emotion_level
    follow_redirect!
    assert_select "#notice", "Entry saved."
  end

  test "only the save that finishes an entry sends up the balloon" do
    @situation.update_column(:balanced_thought, nil)

    patch situation_step_url(@situation, "what-happened"), params: { situation: { title: "Still going" } }
    follow_redirect!
    assert_select "#notice", "Entry saved."
    assert_select "[data-turbo-temporary] svg", count: 0

    patch situation_step_url(@situation, "weigh-it-up"), params: { situation: { balanced_thought: "It went better than I feared." } }
    follow_redirect!
    assert_select "#notice", "Entry complete."
    assert_select "[data-turbo-temporary] svg", count: 1

    patch situation_step_url(@situation, "weigh-it-up"), params: { situation: { balanced_thought: "It went fine." } }
    follow_redirect!
    assert_select "#notice", "Entry saved."
    assert_select "[data-turbo-temporary] svg", count: 0
  end

  test "finishing an entry counts once, and trashing it doesn't take it back" do
    @situation.update_column(:balanced_thought, nil)

    assert_difference -> { @user.reload.finished_entries_count }, 1 do
      patch situation_step_url(@situation, "weigh-it-up"), params: { situation: { balanced_thought: "It went fine." } }
    end
    assert_no_difference -> { @user.reload.finished_entries_count } do
      patch situation_step_url(@situation, "weigh-it-up"), params: { situation: { balanced_thought: "It went well." } }
      delete situation_url(@situation)
    end
  end

  test "the entry that reaches the plant's next stage gets its own moment instead of the balloon" do
    @user.update_column(:finished_entries_count, 9)
    @situation.update_column(:balanced_thought, nil)

    patch situation_step_url(@situation, "weigh-it-up"), params: { situation: { balanced_thought: "It went better than I feared." } }
    follow_redirect!
    assert_select "#notice p", "Entry complete. You planted a seed."
    assert_select "#notice a[href=?]", edit_settings_path(anchor: "plant"), text: "See your plant"
    assert_select "[data-turbo-temporary] img[src*='milestones/seed']", count: 2
    assert_select "[data-turbo-temporary] svg", count: 0
  end

  test "the first step creates the entry, dated now, and moves on" do
    freeze_time do
      assert_difference("@user.situations.count") do
        post situations_url, params: { situation: { thought_imagery: "Nobody replied", emotions: [ "" ] }, go_to: "what-happened" }
      end
      # Found by its answer: under freeze_time a fixture's created_at can tie with or follow the new entry's.
      situation = @user.situations.find_by!(thought_imagery: "Nobody replied")
      assert_redirected_to situation_step_url(situation, "what-happened")
      assert_equal Time.current.change(sec: 0), situation.date
    end
  end

  test "delete hides the entry and offers undo" do
    assert_difference -> { @user.situations.count } => -1, -> { Situation.count } => 0 do
      delete situation_url(@situation)
    end
    assert_redirected_to situations_url

    follow_redirect!
    assert_select "#notice", /Entry deleted/
    assert_select "#notice form[action=?] button", situation_restoration_path(@situation), "Undo"
    assert_no_match @situation.title, response.body

    get situation_url(@situation)
    assert_response :not_found
  end

  test "undo restores a deleted entry, only for its owner" do
    @situation.trash!

    sign_in_as users(:two)
    post situation_restoration_url(@situation)
    assert_response :not_found

    sign_in_as @user
    post situation_restoration_url(@situation)
    assert_redirected_to situation_url(@situation)
    assert_nil @situation.reload.deleted_at
  end

  test "purge job removes entries deleted more than 30 days ago" do
    @situation.update!(deleted_at: 31.days.ago)
    situations(:two).update!(deleted_at: 2.days.ago)

    assert_difference("Situation.count", -1) { PurgeDeletedSituationsJob.perform_now }
    assert Situation.exists?(situations(:two).id)
  end
  test "each step needs its one answer before it saves, and a refused step changes nothing" do
    patch situation_step_url(@situation, "name-the-pattern"), params: { situation: { distortion_ids: [ "" ] }, go_to: "weigh-it-up" }
    assert_response :unprocessable_content
    assert_select "#error_explanation a[href='#situation_distortion_ids']", "Thinking traps need at least one picked"
    assert_equal 2, @situation.reload.distortions.count

    patch situation_step_url(@situation, "what-happened"), params: { situation: { title: " " } }
    assert_select "#situation_title_error", "Short name can't be blank"
    assert_equal "Missed deadline", @situation.reload.title

    patch situation_step_url(@situation, "weigh-it-up"), params: { situation: { balanced_thought: "" } }
    assert_response :unprocessable_content

    assert_no_difference("Situation.count") { post situations_url, params: { situation: { thought_imagery: "", emotions: [ "Sad" ] } } }
    assert_select "#situation_thought_imagery_error", "What went through your mind can't be blank"
  end

  test "form shows a checkbox for each distortion" do
    get situation_step_url(@situation, "name-the-pattern")
    assert_select "input[type=checkbox][name=?]", "situation[distortion_ids][]", count: Distortion.count
    assert_select "input[type=checkbox][checked]", count: 2
  end

  test "form suggests past locations and people" do
    get situation_step_url(@situation, "what-happened")
    assert_select "input[role=combobox][name=?][aria-controls=situation_location_options]", "situation[location]"
    assert_select "#situation_location_options[role=listbox] [role=option]", "Office"
    assert_select "input[role=combobox][name=?][aria-controls=situation_who_was_involved_options]", "situation[who_was_involved]"
    assert_select "#situation_who_was_involved_options [role=option]", "Spouse"
    assert_select "#situation_who_was_involved_options [role=option]", "Manager"
  end

  test "a new place or person is offered the next time" do
    patch situation_step_url(@situation, "what-happened"), params: { situation: { location: "Grocery store", who_was_involved: "Neighbor" } }

    get situation_step_url(@situation, "what-happened")
    assert_select "#situation_location_options [role=option]", "Grocery store"
    assert_select "#situation_who_was_involved_options [role=option]", "Neighbor"
  end

  test "an entry shows Continue until it's finished, then Edit" do
    @situation.update_column(:balanced_thought, nil)
    get situation_url(@situation)
    assert_select "a[href=?]", situation_step_path(@situation, "weigh-it-up"), text: "Continue"
    assert_select "a", text: "Edit", count: 0

    @situation.update_column(:balanced_thought, "It went better than I feared.")
    get situation_url(@situation)
    assert_select "a[href=?]", situation_step_path(@situation, "whats-on-your-mind"), text: "Edit"
    assert_select "a", text: "Continue", count: 0
  end

  test "the journal marks entries in progress" do
    @situation.update_column(:balanced_thought, nil)
    get situations_url
    assert_select "##{dom_id @situation} .badge-sky", "In progress"
    assert_select ".badge-sky", count: 1
  end

  test "suggestions are listed alphabetically" do
    get situation_step_url(@situation, "what-happened")
    people = css_select("#situation_who_was_involved_options [role=option]").map(&:text)
    assert_equal people.sort_by(&:downcase), people
  end

  test "dates are entered in the user's time zone" do
    patch situation_step_url(@situation, "what-happened"), params: { situation: { date: "2026-10-01T21:00" } }
    assert_equal Time.utc(2026, 10, 2, 1, 0), @situation.reload.date
  end

  test "index sidebar summarizes the last 30 days with links to insights" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      get situations_url
      assert_select "#summary_heading", text: "Last 30 days"
      assert_select "a[href=?]", insights_path(distortion_id: distortions(:catastrophizing).id, range: "30"), text: /Catastrophizing/
    end
  end

  test "index has no summary without recent entries" do
    sign_in_as users(:admin)
    get situations_url
    assert_select "#summary_heading", count: 0
  end

  test "exports only the current user's entries as CSV, in their time zone" do
    @user.update!(time_zone: "America/Los_Angeles")
    @situation.update!(distortion_ids: [ distortions(:mind_reading).id, distortions(:catastrophizing).id ], evidence_for: "=HYPERLINK(1)")

    get situations_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/attachment; filename="beckit-entries-\d{4}-\d{2}-\d{2}\.csv"/, response.headers["Content-Disposition"])

    rows = CSV.parse(response.body)
    assert_equal Situation::CSV_HEADERS, rows.first
    assert_equal 2, rows.size
    assert_equal [ "2026-10-01 02:00", "Missed deadline" ], rows.second.first(2)
    assert_equal "Catastrophizing; Mind reading", rows.second[7]
    assert_equal "'=HYPERLINK(1)", rows.second[8]
  end

  test "form saves drafts per user and per entry" do
    get new_situation_url
    assert_select "form[data-controller~=draft][data-draft-key-value=?]", "draft:#{@user.id}:new"
    assert_select "[data-draft-target=notice][hidden]"

    get situation_step_url(@situation, "weigh-it-up")
    assert_select "form[data-draft-key-value=?]", "draft:#{@user.id}:#{@situation.id}:weigh-it-up"
  end

  test "an entry reads as one record: the thought and feeling first, the balanced thought and feeling afterwards last" do
    @situation.update!(emotion_level: 7, emotion_level_after: 4, balanced_thought: "It went better than I feared.")
    get situation_url(@situation)
    assert_select "ol[aria-label=?] > li", "The thought record", 4
    assert_select "ol > li:first-child #feeling_before", /7/
    assert_select "ol > li:last-child #balanced_heading", "A more balanced thought"
    assert_select "ol > li:last-child #feeling_after", /4/
    assert_select "#feeling_shift", "Down 3 from 7"
  end

  test "the first step asks for the thought and feelings; the short name comes later, with no default" do
    get new_situation_url
    assert_select "form[action=?][method=post]", situations_path do
      assert_select "h1", "What's on your mind"
      assert_select "textarea[name=?][required]", "situation[thought_imagery]"
      assert_select "input[type=checkbox][name=?]", "situation[emotions][]", count: Situation::EMOTIONS.size
      assert_select "input[name=?]", "situation[title]", count: 0
    end

    post situations_url, params: { situation: { thought_imagery: "Everyone in the room could tell" }, go_to: "what-happened" }
    follow_redirect!
    assert_select "input[name=?][required]:not([value])", "situation[title]"
    assert_select "input[type=datetime-local][step='60']" do |field|
      assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}\z/, field.first["value"])
    end

    get situation_step_url(@situation, "weigh-it-up")
    assert_select "input[type=radio][name=?]", "situation[emotion_level_after]", count: 12
  end

  test "form puts the user's most-used thinking traps first, with descriptions in a disclosure" do
    get situation_step_url(@situation, "name-the-pattern")
    chips = css_select("input[name='situation[distortion_ids][]']").map { it["value"] }.compact_blank
    assert_equal [ distortions(:catastrophizing), distortions(:mind_reading) ].map { it.id.to_s }, chips.first(2)
    assert_select "details summary", /What do these mean/
    assert_select "details dd[id=?]", "situation_distortion_ids_#{distortions(:catastrophizing).id}_description"
  end

  test "every step reaches every other: back by link, forward by buttons that save; Enter means Next" do
    get situation_step_url(@situation, "what-happened")
    assert_select "form[action=?]", situation_step_path(@situation, "what-happened") do
      assert_select "button[type=submit].sr-only[name=go_to][value=name-the-pattern]:first-of-type"
      assert_select "nav a[href=?]", situation_step_path(@situation, "whats-on-your-mind")
      assert_select "nav button[name=go_to]", count: 3
      assert_select "nav button[aria-current=step]", /What happened/
      assert_select "a[href=?]", situation_step_path(@situation, "whats-on-your-mind"), /Back/
      assert_select "button[name=go_to][value=name-the-pattern]", "Next"
      assert_select "button:not([name=go_to])", "Save entry"
    end

    get situation_step_url(@situation, "weigh-it-up")
    assert_select "button", text: "Next", count: 0
    assert_select "button.sr-only:not([name=go_to])"
    assert_select "figure blockquote", @situation.thought_imagery if @situation.thought_imagery.present?
  end

  test "steps open in order, up to the first one still waiting for its answer" do
    get new_situation_url
    assert_select "nav button[name=go_to][value=what-happened]"
    assert_select "nav span[aria-disabled=true]", count: 2

    unfinished = @user.situations.create!(date: Time.current, thought_imagery: "I froze")
    get situation_step_url(unfinished, "weigh-it-up")
    assert_redirected_to situation_step_url(unfinished, "what-happened")

    get situation_step_url(unfinished, "what-happened")
    assert_response :success
    assert_select "nav button[name=go_to][value=name-the-pattern]"
    assert_select "nav span[aria-disabled=true]", /Weigh it up/

    get situation_step_url(@situation, "whats-on-your-mind")
    assert_select "nav span[aria-disabled]", count: 0
  end

  test "unfinished entries offer to continue at the step waiting for an answer" do
    unfinished = @user.situations.create!(date: Time.current, thought_imagery: "I froze", title: "Stand-up")

    get situations_url
    assert_select "##{dom_id(unfinished)} a[href=?]", situation_step_path(unfinished, "name-the-pattern"), /Continue this entry/
    assert_select "##{dom_id(@situation)} a", count: 1

    get situation_url(unfinished)
    assert_select "a.btn-primary[href=?]", situation_step_path(unfinished, "name-the-pattern"), "Continue"

    get situation_url(@situation)
    assert_select "a", text: "Continue", count: 0
  end

  test "a failed save stays on its step with the error" do
    patch situation_step_url(@situation, "what-happened"), params: { situation: { date: "" }, go_to: "name-the-pattern" }
    assert_response :unprocessable_content
    assert_select "h1", "What happened"
    assert_select "input#situation_date[aria-invalid=true]"
  end

  test "creates an entry with feelings, a re-rating and no short name yet" do
    post situations_url, params: { situation: { date: "2026-10-05T08:30", thought_imagery: "They are all judging me", emotions: [ "", "Anxious", "Ashamed" ], emotion_level: 8, emotion_level_after: 5 } }
    situation = @user.situations.find_by!(thought_imagery: "They are all judging me")
    assert_nil situation.title
    assert_equal [ "They are all judging me", %w[ Anxious Ashamed ], 5 ], [ situation.display_title, situation.emotions, situation.emotion_level_after ]

    follow_redirect!
    assert_select "#notice", "Entry saved."
    assert_select "li.badge-neutral", "Anxious"
    assert_select "#feeling_shift", "Down 3 from 8"
  end

  test "index keeps search folded away until a search is showing" do
    get situations_url
    assert_select "details:not([open]) form[role=search]"

    get situations_url(q: "fired")
    assert_select "details[open] form[role=search]"
  end

  test "index searches and filters by thinking trap" do
    get situations_url(q: "fired")
    assert_select "#situations h3", text: "Missed deadline"
    assert_select "#filter_heading", "Search results"
    assert_select "[role=status]", "1 entry matches “fired”."

    get situations_url(q: "nothing like this")
    assert_select "#situations h3", count: 0
    assert_select "p", /No entries match/

    @user.situations.create!(title: "Untagged", date: 1.day.ago)
    get situations_url(distortion_id: distortions(:catastrophizing).id)
    assert_select "#situations h3", count: 1
    assert_select "select[name=distortion_id] option[selected]", "Catastrophizing"
    assert_select "#filter_heading", "Catastrophizing"
    assert_select "section[aria-labelledby=filter_heading] a[href=?]", situations_path, "Show all entries"
    assert_select "a[href^='/insights']", { text: /Catastrophizing insights/, count: 0 }
  end

  test "a journal filtered from Insights links back to the same Insights view" do
    catastrophizing = distortions(:catastrophizing)
    get situations_url(distortion_id: catastrophizing.id, insights_range: "365")
    assert_select "title", /Catastrophizing entries/
    assert_select "section[aria-labelledby=filter_heading] a[href=?]", insights_path(distortion_id: catastrophizing.id, range: "365"), text: /Catastrophizing insights/
    assert_select "[role=status]", /across your whole journal/

    get situations_url(distortion_id: catastrophizing.id, insights_range: "bogus")
    assert_select "a", { text: /Catastrophizing insights/, count: 0 }
  end

  test "index pages 20 at a time under month headings" do
    21.times { |i| @user.situations.create!(title: "Entry #{i}", date: Time.zone.local(2026, 9, 1, 9) + i.days) }

    get situations_url
    assert_select "#situations section > ul > li", 20
    assert_select "#situations h2", "September 2026"
    assert_select "#page_status", count: 0
    assert_select "nav[aria-label=Pages]", /Page 1 of 2/
    assert_select "nav[aria-label=Pages] a[href=?]", situations_path(page: 2, anchor: "entries"), /Older entries/
    assert_select "title", "Journal"

    get situations_url(page: 2)
    assert_select "#situations section > ul > li", 2
    assert_select "#situations h2", "September 2026, continued"
    assert_select "#page_status", /Page 2 of 2\s*Entries from Sep 2, 2026 back to Sep 1, 2026/
    assert_select "#page_status a[href=?]", situations_path(anchor: "entries"), /Newest entries/
    assert_select "nav[aria-label=Pages] a[href=?]", situations_path(anchor: "entries"), /Newer entries/
    assert_select "nav[aria-label=Pages] a", { text: /Older/, count: 0 }
    assert_select "title", "Journal, page 2"
  end

  test "only the month carried over from the page before is called continued" do
    # With the fixture's October 1 entry, page 2 starts with the last October entry, then September begins.
    20.times { |i| @user.situations.create!(title: "October #{i}", date: Time.zone.local(2026, 10, 2, 9) + i.hours) }
    @user.situations.create!(title: "September", date: Time.zone.local(2026, 9, 30, 9))

    get situations_url(page: 2)
    assert_select "#situations h2" do |headings|
      assert_equal [ "October 2026, continued", "September 2026" ], headings.map(&:text)
    end
  end

  test "an empty journal shows the intro with time zone and crisis line prompts" do
    admin = users(:admin)
    sign_in_as admin
    get situations_url
    assert_select "#intro_heading", "A quiet place to begin"
    assert_select "#intro_time_zone", /Eastern Time/
    assert_select "#intro_crisis_line", count: 0
    assert_select "form[role=search]", count: 0

    admin.update!(time_zone: "Europe/London")
    get situations_url
    assert_select "#intro_crisis_line", /Add a crisis line/
  end

  test "invalid feelings link to the feelings group, not an inline message" do
    post situations_url, params: { situation: { date: "2026-10-05T08:30", thought_imagery: "Nothing to do", emotions: [ "Bored" ] } }
    assert_response :unprocessable_content
    assert_select "#error_explanation a[href='#situation_emotions']"
    assert_select "fieldset#situation_emotions"
    assert_select ".field-error", count: 0
  end

  test "on small screens the 30-day summary follows the entries" do
    get situations_url
    assert_select "aside section.max-lg\\:hidden #summary_heading"
    assert_select "#situations ~ section.lg\\:hidden #summary_mobile_heading", "Last 30 days"
    assert_select "a", "See 30-day insights"
  end
end
