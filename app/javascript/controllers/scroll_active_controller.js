import { Controller } from "@hotwired/stimulus"

// Keeps the selected chip visible when the distortion rail scrolls sideways on small screens.
export default class extends Controller {
  connect() {
    this.element.querySelector("[aria-current]")?.scrollIntoView({ block: "nearest", inline: "center", behavior: "instant" })
  }
}
