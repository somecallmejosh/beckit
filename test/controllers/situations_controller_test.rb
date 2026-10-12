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
      post situations_url, params: { situation: { title: "New one", date: Time.current, distortion_ids: [ distortions(:catastrophizing).id, distortions(:mind_reading).id ], emotion_level: 3, user_id: users(:two).id } }
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

  test "should get edit" do
    get edit_situation_url(@situation)
    assert_response :success
  end

  test "should update situation" do
    patch situation_url(@situation), params: { situation: { title: "Updated", emotion_level: 4 } }
    assert_redirected_to situation_url(@situation)
    assert_equal "Updated", @situation.reload.title
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
  test "should clear distortions when none are checked" do
    patch situation_url(@situation), params: { situation: { distortion_ids: [ "" ] } }
    assert_redirected_to situation_url(@situation)
    assert_empty @situation.reload.distortions
  end

  test "form shows a checkbox for each distortion" do
    get edit_situation_url(@situation)
    assert_select "input[type=checkbox][name=?]", "situation[distortion_ids][]", count: Distortion.count
    assert_select "input[type=checkbox][checked]", count: 2
  end

  test "form suggests past locations and people" do
    get new_situation_url
    assert_select "input[name=?][list=location_options]", "situation[location]"
    assert_select "datalist#location_options option[value=Office]"
    assert_select "input[name=?][list=who_options]", "situation[who_was_involved]"
    assert_select "datalist#who_options option[value=Spouse]"
    assert_select "datalist#who_options option[value=Manager]"
  end

  test "dates are entered in the user's time zone" do
    post situations_url, params: { situation: { title: "Late night", date: "2026-10-01T21:00" } }
    assert_equal Time.utc(2026, 10, 2, 1, 0), Situation.last.date
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
    assert_select "form[data-controller=draft][data-draft-key-value=?]", "draft:#{@user.id}:new"
    assert_select "[data-draft-target=notice][hidden]"

    get edit_situation_url(@situation)
    assert_select "form[data-draft-key-value=?]", "draft:#{@user.id}:#{@situation.id}"
  end

  test "entry aside sticks below the header" do
    get situation_url(@situation)
    assert_select "aside.lg\\:top-24"
  end

  test "form leads with the thought and feelings, and the title is optional" do
    get new_situation_url
    fields = css_select("form[data-controller=draft] textarea, form[data-controller=draft] input[type=text]").map { it["name"] }
    assert_operator fields.index("situation[thought_imagery]"), :<, fields.index("situation[title]")
    assert_select "input[name=?]:not([required])", "situation[title]"
    assert_select "input[type=checkbox][name=?]", "situation[emotions][]", count: Situation::EMOTIONS.size
    assert_select "input[type=radio][name=?]", "situation[emotion_level_after]", count: 12
    assert_select "input[type=datetime-local][step='60']" do |field|
      assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}\z/, field.first["value"])
    end
  end

  test "form puts the user's most-used thinking traps first, with descriptions in a disclosure" do
    get new_situation_url
    chips = css_select("input[name='situation[distortion_ids][]']").map { it["value"] }.compact_blank
    assert_equal [ distortions(:catastrophizing), distortions(:mind_reading) ].map { it.id.to_s }, chips.first(2)
    assert_select "details summary", /What do these mean/
    assert_select "details dd[id=?]", "situation_distortion_ids_#{distortions(:catastrophizing).id}_description"
  end

  test "creates an entry with feelings, a re-rating and no title" do
    post situations_url, params: { situation: { date: "2026-10-05T08:30", thought_imagery: "They are all judging me", emotions: [ "", "Anxious", "Ashamed" ], emotion_level: 8, emotion_level_after: 5 } }
    situation = @user.situations.order(:created_at).last
    assert_equal [ "They are all judging me", %w[ Anxious Ashamed ], 5 ], [ situation.title, situation.emotions, situation.emotion_level_after ]

    follow_redirect!
    assert_select "#notice", "Entry saved."
    assert_select "li.badge-neutral", "Anxious"
    assert_select "section[aria-labelledby=feeling_heading] p", "Down 3 from 8"
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
    assert_select "nav[aria-label=Pages] a", "Older entries"

    get situations_url(page: 2)
    assert_select "#situations section > ul > li", 2
    assert_select "#situations h2", "September 2026"
    assert_select "nav[aria-label=Pages] a[href=?]", situations_path, /Newer entries/
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
    post situations_url, params: { situation: { date: "2026-10-05T08:30", emotions: [ "Bored" ] } }
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
