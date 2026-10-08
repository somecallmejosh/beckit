require "test_helper"

class DistortionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @distortion = distortions(:catastrophizing)
    sign_in_as users(:admin)
  end

  test "requires authentication" do
    sign_out
    get distortions_url
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
