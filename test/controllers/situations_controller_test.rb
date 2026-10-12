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

  test "should destroy situation" do
    assert_difference("Situation.count", -1) do
      delete situation_url(@situation)
    end

    assert_redirected_to situations_url
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
    assert_equal "Catastrophizing; Mind reading", rows.second[6]
    assert_equal "'=HYPERLINK(1)", rows.second[7]
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
    assert_select "aside.lg\\:top-20"
  end
end
