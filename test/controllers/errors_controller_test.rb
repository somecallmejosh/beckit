require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "not found page" do
    get "/404"
    assert_response :not_found
    assert_select "title", "Page not found · beckit"
    assert_select "h1", "This page wandered off"
    assert_select "img[src*='not-found'][alt]"
    assert_select "a[href=?]", root_path, text: "Take me home"
    assert_select "a[href='tel:988']"
  end

  test "server error page" do
    get "/500"
    assert_response :internal_server_error
    assert_select "h1", "Something went wrong on our end"
    assert_select "img[src*='server-error'][alt]"
    assert_select "a[href=?]", root_path, text: "Take me home"
  end

  test "a failed POST still gets the page, not a CSRF error" do
    ActionController::Base.allow_forgery_protection = true
    post "/404"
    assert_response :not_found
    assert_select "h1", "This page wandered off"
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "non-HTML requests get the status alone" do
    get "/404.png"
    assert_response :not_found
    assert_empty response.body
  end

  test "a missing record shows the not found page, as in production" do
    Rails.application.env_config.merge!("action_dispatch.show_exceptions" => :all, "action_dispatch.show_detailed_exceptions" => false)
    get distortion_url(id: "no-such-trap")
    assert_response :not_found
    assert_select "h1", "This page wandered off"
  ensure
    Rails.application.env_config.merge!("action_dispatch.show_exceptions" => :rescuable, "action_dispatch.show_detailed_exceptions" => true)
  end

  test "exceptions_app sends 404 and 500 to the error pages and other statuses to public/" do
    exceptions_app = Rails.application.config.exceptions_app

    status, _, body = exceptions_app.call(Rack::MockRequest.env_for("/404", "HTTP_ACCEPT" => "text/html"))
    assert_equal 404, status
    assert_includes body.each.to_a.join, "This page wandered off"

    status, _, body = exceptions_app.call(Rack::MockRequest.env_for("/500", "HTTP_ACCEPT" => "text/html"))
    assert_equal 500, status
    assert_includes body.each.to_a.join, "Something went wrong on our end"

    status, _, body = exceptions_app.call(Rack::MockRequest.env_for("/422", "HTTP_ACCEPT" => "text/html"))
    assert_equal 422, status
    assert_includes body.each.to_a.join, File.read(Rails.public_path.join("422.html"))[0, 100]
  end
end
