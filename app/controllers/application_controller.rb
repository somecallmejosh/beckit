class ApplicationController < ActionController::Base
  include Authentication

  # Shown by every rate_limit. The limits reset after 3 minutes, so it says how long to wait.
  RATE_LIMITED = "Too many tries in a row. Wait a few minutes, then try again."

  # The journal needs a modern browser (webp, web push, badges, import maps, CSS nesting and :has). Public pages
  # skip the check: link-preview bots (iMessage, Messenger and others) send old browser user agents and would get
  # a 406 instead of the title, description and share image.
  allow_browser versions: :modern, if: :authenticated?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :use_user_time_zone

  private
    def use_user_time_zone(&)
      Time.use_zone(Current.user&.time_zone || "UTC", &)
    end
end
