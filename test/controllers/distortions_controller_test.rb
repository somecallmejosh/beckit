require "test_helper"

class DistortionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @distortion = distortions(:catastrophizing)
    sign_in_as users(:admin)
  end

  test "index and show are public, with the landing nav and no personal panel" do
    sign_out
    get distortions_url
    assert_response :success
    assert_select "h1", "Thinking traps"
    assert_select "a[href=?]", new_registration_path
    assert_select "a[href=?]", edit_distortion_path(@distortion), count: 0

    get distortion_url(@distortion)
    assert_response :success
    assert_select "h2", "Notice this in your own thinking?"
    assert_select "h2", text: "Your recent entries", count: 0
  end

  test "signed-in visitors still get admin controls and their entries" do
    get distortions_url
    assert_select "a[href=?]", edit_distortion_path(@distortion)
    assert_select "header nav[aria-label=Main] a[aria-current=page]", "Thinking traps"

    get distortion_url(@distortion)
    assert_select "h2", "Your recent entries"
  end

  test "editing still requires sign-in" do
    sign_out
    get new_distortion_url
    assert_redirected_to new_session_url
  end

  test "should get index" do
    get distortions_url
    assert_response :success
  end

  test "should get new" do
    get new_distortion_url
    assert_response :success
  end

  test "should create distortion" do
    assert_difference("Distortion.count") do
      post distortions_url, params: { distortion: { title: "Labeling", description: "Attaching a global label." } }
    end

    assert_redirected_to distortion_url(Distortion.last)
  end

  test "should not create invalid distortion" do
    assert_no_difference("Distortion.count") do
      post distortions_url, params: { distortion: { title: "", description: "" } }
    end

    assert_response :unprocessable_content
  end

  test "should show distortion" do
    get distortion_url(@distortion)
    assert_response :success
  end

  test "show uses the trap's photo, social card and details" do
    perform_enqueued_jobs do
      @distortion.update!(image: fixture_file_upload("trap.webp", "image/webp"), details: "<h1>Examples</h1><ul><li>One mistake ruins the day.</li></ul>")
    end
    get distortion_url(@distortion)
    assert_select "main img[src*='/rails/active_storage/']"
    assert_select "meta[property='og:image'][content*='/rails/active_storage/blobs/']"
    assert_select "meta[property='og:description'][content=?]", @distortion.description
    assert_select ".rich-text h1", "Examples"
    assert_select ".rich-text li", "One mistake ruins the day."
  end

  test "index shows each trap's photo, or a named tile when it has none" do
    @distortion.update!(image: fixture_file_upload("trap.webp", "image/webp"))
    get distortions_url
    assert_select "##{dom_id @distortion} img[src*='/rails/active_storage/']"
    assert_select "##{dom_id distortions(:mind_reading)} img", count: 0
    assert_select "##{dom_id distortions(:mind_reading)} [aria-hidden=true]", "Mind reading"
    assert_select "##{dom_id @distortion} a[href=?]", distortion_url(@distortion).delete_prefix("http://www.example.com")
  end

  test "show falls back to the site social card when a trap has no photo" do
    get distortion_url(@distortion)
    assert_select "main img[src*='/rails/active_storage/']", count: 0
    assert_select "meta[property='og:image'][content$=?]", "/og-image.png"
    assert_select ".rich-text", count: 0
  end

  test "admins can upload a photo and write details" do
    patch distortion_url(@distortion), params: { distortion: { image: fixture_file_upload("trap.webp", "image/webp"), details: "<p>More to say.</p>" } }
    assert_redirected_to distortion_url(@distortion)
    @distortion.reload
    assert @distortion.image.attached?
    assert_equal "More to say.", @distortion.details.to_plain_text
    assert_enqueued_with job: Distortion::RefreshOgImageJob, args: [ @distortion ]
  end

  test "rejects a photo that is not an image" do
    patch distortion_url(@distortion), params: { distortion: { image: fixture_file_upload("not-an-image.txt", "text/plain") } }
    assert_response :unprocessable_content
    assert_not @distortion.reload.image.attached?
  end

  test "show lists only the current user's entries with that distortion" do
    sign_in_as users(:two)
    get distortion_url(distortions(:mind_reading))
    assert_select "#recent_entries_heading"
    assert_select "section[aria-labelledby=recent_entries_heading] li span", count: 1, text: situations(:two).title
    assert_select "li span", text: situations(:one).title, count: 0
  end

  test "show has an empty state when no entries use the distortion" do
    get distortion_url(@distortion)
    assert_select "p", text: "You haven't tagged an entry with catastrophizing yet."
  end

  test "should get edit" do
    get edit_distortion_url(@distortion)
    assert_response :success
  end

  test "should update distortion" do
    patch distortion_url(@distortion), params: { distortion: { description: "Updated" } }
    assert_redirected_to distortion_url(@distortion)
    assert_equal "Updated", @distortion.reload.description
  end

  test "should destroy distortion" do
    assert_difference("Distortion.count", -1) do
      delete distortion_url(@distortion)
    end

    assert_redirected_to distortions_url
  end
  test "non-admins can view distortions" do
    sign_out
    sign_in_as users(:one)

    get distortions_url
    assert_response :success
    assert_select "a", text: "New distortion", count: 0

    get distortion_url(@distortion)
    assert_response :success
    assert_select "a", text: "Edit", count: 0
  end

  test "non-admins cannot change distortions" do
    sign_out
    sign_in_as users(:one)

    get new_distortion_url
    assert_redirected_to root_url

    get edit_distortion_url(@distortion)
    assert_redirected_to root_url

    assert_no_difference("Distortion.count") do
      post distortions_url, params: { distortion: { title: "Labeling", description: "Attaching a global label." } }
    end
    assert_redirected_to root_url

    patch distortion_url(@distortion), params: { distortion: { description: "Hacked" } }
    assert_redirected_to root_url
    assert_not_equal "Hacked", @distortion.reload.description

    assert_no_difference("Distortion.count") do
      delete distortion_url(@distortion)
    end
    assert_redirected_to root_url
  end
end
