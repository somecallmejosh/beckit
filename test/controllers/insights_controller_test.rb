require "test_helper"

class InsightsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "requires authentication" do
    sign_out
    get insights_url
    assert_redirected_to new_session_url
  end

  test "header shows the drawing beside the heading" do
    get insights_url
    assert_select "h1", "Insights"
    assert_select "img[src*='insights'][alt='']"
  end

  test "shows every distortion for each range" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      DistortionInsights::RANGES.each_key do |range|
        get insights_url(range:)
        assert_response :success
        assert_select "nav[aria-label='Thinking traps'] a", count: Distortion.count + 1
      end
    end
  end

  test "focuses on a distortion" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      get insights_url(distortion_id: distortions(:mind_reading).id)
      assert_response :success
      assert_select "#profile_heading", text: "Mind reading"
      assert_select "nav[aria-label='Thinking traps'] a[aria-current=page]", text: /Mind reading/
      assert_select "#standouts_heading + ul li", text: /Came up in 1 of your 1 entry/
      assert_select "#place_heading"
      assert_select "#strongest_heading", count: 0
    end
  end

  test "shows the empty state when there are no entries in range" do
    sign_in_as users(:admin)
    get insights_url
    assert_response :success
    assert_match "Nothing to show yet", response.body
  end

  test "marks carry tooltip text and the tooltip is wired up" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      get insights_url(distortion_id: distortions(:mind_reading).id)
      assert_select "[data-controller=tooltip] [data-tooltip-target=tip][hidden]"
      assert_select "td[data-tooltip][data-tooltip-detail]", minimum: 35
      assert_select "[title]:not(th)", count: 0
    end
  end

  test "tooltips only where they add detail the page doesn't show" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      get insights_url(range: "all")
      assert_select "section[aria-labelledby=heatmap_heading] table td", minimum: 35
      assert_select "section[aria-labelledby=heatmap_heading] table [data-tooltip]", count: 0
      assert_select "section[aria-labelledby=pairs_heading] ul [data-tooltip]", count: 0
      assert_select "section[aria-labelledby=pairs_heading] ul li", text: /1 entry \(\d+%\)/
      assert_select "section[aria-labelledby=weekly_heading] div [data-tooltip]", minimum: 1

      get insights_url(range: "all", distortion_id: distortions(:catastrophizing).id)
      assert_select "section[aria-labelledby=place_heading] ul [data-tooltip]", count: 0
    end
  end

  test "shows distortions logged together" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      get insights_url
      assert_select "#pairs_heading", text: "Together"
      assert_match "Catastrophizing + Mind reading", response.body
    end
  end

  test "overview marks All thinking traps as current and shows overview sections" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      get insights_url
      assert_select "nav[aria-label='Thinking traps'] a[aria-current=page]", text: /All thinking traps/
      assert_select "#strongest_heading"
      assert_select "#profile_heading", count: 0
    end
  end

  test "rail, range and panel links swap only the insights frame" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      get insights_url
      assert_select "turbo-frame#insights_body[data-turbo-action=advance] nav[aria-label='Thinking traps']"
      assert_select "turbo-frame#insights_body nav[aria-label='Time range']"
      assert_select "meta[name=turbo-cache-control][content=no-cache]", 1, "back/forward must re-fetch, not restore stale frame snapshots"

      get insights_url(distortion_id: distortions(:mind_reading).id), headers: { "Turbo-Frame" => "insights_body" }
      assert_response :success
      assert_select "turbo-frame#insights_body #profile_heading", text: "Mind reading"
      assert_select "nav[aria-label=Main]", count: 0
    end
  end

  test "profile for a distortion with no entries in range" do
    travel_to Time.zone.local(2026, 10, 7, 12) do
      sign_in_as users(:two)
      get insights_url(distortion_id: distortions(:catastrophizing).id, range: "30")
      assert_select "#profile_heading", text: "Catastrophizing"
      assert_select "p", text: /No entries with catastrophizing in the last 30 days/
    end
  end

  test "overview leads with a plain summary and tucks the where/who tables away" do
    situations(:one).update!(emotion_level_after: 4)
    get insights_url(range: "all")
    assert_select "#in_short_heading", "In short"
    assert_select "ul li", /In the 1 entry you re-rated, the feeling dropped by 4 points on average/
    assert_select "details summary", /Where and who, in detail/
    assert_select "details #place_heading"
  end

  test "small screens pick a thinking trap from a select; tables are keyboard navigable" do
    get insights_url(range: "all")
    assert_select "form[data-controller=autosubmit] select[name=distortion_id] option", Distortion.count + 1
    assert_select "nav[aria-label='Thinking traps'].max-lg\\:hidden"
    assert_select "table[data-controller=cell-nav] caption", /arrow keys/
    assert_select "[data-action*='focusin->tooltip#show']"
  end

  test "profile links to the journal filtered by that thinking trap" do
    get insights_url(range: "all", distortion_id: distortions(:catastrophizing).id)
    assert_select "a[href=?][data-turbo-frame=_top]", situations_path(distortion_id: distortions(:catastrophizing).id, insights_range: "all")
  end
end
