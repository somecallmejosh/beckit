import { Controller } from "@hotwired/stimulus"

// Submits the form when a control changes. The fallback button is only for when JavaScript is off.
export default class extends Controller {
  static targets = [ "button" ]

  connect() {
    if (this.hasButtonTarget) this.buttonTarget.hidden = true
  }

  submit() {
    this.element.requestSubmit()
  }
}
