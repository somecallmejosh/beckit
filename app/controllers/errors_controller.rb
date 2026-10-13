# Rendered by config.exceptions_app for 404s and 500s. Not an ApplicationController on purpose: no session lookup,
# browser check or forgery check, so the error page still renders when the database is what failed, and a POST to
# a missing URL gets a 404 instead of a CSRF error.
class ErrorsController < ActionController::Base
  skip_forgery_protection
  layout "errors"

  # GET /404
  def not_found
    render_error :not_found
  end

  # GET /500
  def internal_server_error
    render_error :internal_server_error
  end

  private
    # Missing images, JSON and the like get the status alone, not a page.
    def render_error(status)
      respond_to do |format|
        format.html { render status: }
        format.any { head status }
      end
    end
end
