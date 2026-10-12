import { Controller } from "@hotwired/stimulus"

// Fills a hidden field with the browser's IANA time zone so new accounts don't start on the server default.
export default class extends Controller {
  connect() {
    this.element.value ||= Intl.DateTimeFormat().resolvedOptions().timeZone || ""
  }
}
