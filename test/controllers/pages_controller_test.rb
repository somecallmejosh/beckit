require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors see the landing page" do
    get root_url
    assert_response :success
    assert_select "h1", "Notice the thought. Name the pattern."
    assert_select "a[href=?]", new_registration_path, text: "Start your journal", minimum: 2
    assert_select "a[href=?]", new_session_path, text: "Sign in", minimum: 2
    assert_select "header nav[aria-label=Main]", count: 0
  end

  test "states plainly that it is not therapy" do
    get root_url
    assert_select "#is_isnt_heading + div li", text: "Therapy, or a substitute for it."
    assert_select "footer p", text: "beckit is a self-help journaling tool. It does not provide therapy, diagnosis or medical advice."
    assert_select "a[href='tel:988']", minimum: 1
  end

  test "shows the insights features with labeled example data" do
    get root_url
    %w[ standouts_heading weekly_heading heatmap_heading place_heading pairs_heading ].each { |id| assert_select "##{id}" }
    assert_select "[data-controller=tooltip] [data-tooltip-target=tip]"
    assert_select "td[data-tooltip]", minimum: 35
    assert_select "p", text: "Example data. Your insights come from your own entries."
  end

  test "lists every distortion" do
    get root_url
    Distortion.pluck(:title).each { |title| assert_match title, response.body }
  end

  test "uses only one label per call to action and no dashes" do
    get root_url
    assert_no_match(/[—–]/, response.body)
    assert_no_match(/Create account|Get started|Sign up/, response.body)
  end

  test "signed-in visitors go to their journal, keeping any flash" do
    sign_in_as users(:one)
    get root_url
    assert_redirected_to situations_url

    get new_distortion_url
    assert_redirected_to root_url
    follow_redirect!
    assert_redirected_to situations_url
    follow_redirect!
    assert_select "#alert", "You are not authorized to do that."
  end

  test "privacy page is public and describes the account controls" do
    get privacy_url
    assert_response :success
    assert_select "h1", "Privacy"
    assert_select "h2", "Your controls"
    assert_no_match(/[—–]/, response.body)
  end

  test "pages load no third-party fonts, styles or images" do
    [ root_url, privacy_url, distortions_url, new_session_url ].each do |url|
      get url
      assert_select "link[href^='http'], script[src^='http'], img[src^='http']", count: 0
    end
  end

  test "footer links to thinking traps and privacy" do
    get root_url
    assert_select "footer nav a[href=?]", distortions_path, "Thinking traps"
    assert_select "footer nav a[href=?]", privacy_path, "Privacy"
  end
end
