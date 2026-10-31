import { Controller } from "@hotwired/stimulus"

// Offers questions to test a thought with, one at a time (Weigh it up). The first is in the page already; "Another
// question" steps through the rest and back round. The button shows only when there's more than one.
export default class extends Controller {
  static targets = [ "text", "another" ]
  static values = { questions: Array }

  connect() {
    this.index = 0
    this.anotherTarget.hidden = this.questionsValue.length < 2
  }

  another() {
    this.index = (this.index + 1) % this.questionsValue.length
    this.textTarget.textContent = this.questionsValue[this.index]
  }
}
