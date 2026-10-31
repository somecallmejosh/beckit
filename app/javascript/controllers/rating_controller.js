import { Controller } from "@hotwired/stimulus"

// A 0-10 rating as a slider (situations/_intensity). The radios underneath stay the form's answer: dragging checks the
// matching one, so drafts and the server see what they always did. Until it's dragged (or with Skip checked) the slider
// rests at 5, faded, and reads "Not rated". Without JavaScript the numbered radios show instead.
export default class extends Controller {
  static targets = [ "slider", "range", "choices", "skip", "number", "word", "weather" ]
  static values = { words: Array }

  connect() {
    this.choicesTarget.hidden = true
    this.sliderTarget.hidden = false

    const checked = this.radios.find(radio => radio.checked && radio.value !== "")
    this.show(checked ? Number(checked.value) : null)
  }

  // input on the range: check the radio for this level and let the draft know.
  slide() {
    const level = Number(this.rangeTarget.value)
    const radio = this.radios.find(radio => radio.value === String(level))
    radio.checked = true
    radio.dispatchEvent(new Event("change", { bubbles: true }))
    this.show(level)
  }

  // change on Skip: the slider goes back to resting.
  skipped() {
    if (this.skipTarget.checked) this.show(null)
  }

  show(level) {
    const rated = level !== null
    this.rangeTarget.value = rated ? level : 5
    this.rangeTarget.toggleAttribute("data-unrated", !rated)
    this.rangeTarget.setAttribute("aria-valuetext", rated ? `${level}, ${this.wordsValue[level].toLowerCase()}` : "Not rated")
    this.numberTarget.textContent = rated ? level : "–"
    this.wordTarget.textContent = rated ? this.wordsValue[level] : "Not rated yet. Drag to rate."

    const shown = rated ? this.weatherTargets.find(svg => level <= Number(svg.dataset.max)) : this.weatherTargets[2]
    this.weatherTargets.forEach(svg => svg.toggleAttribute("hidden", svg !== shown))
    this.weatherTargets.forEach(svg => svg.classList.toggle("opacity-40", !rated))
  }

  get radios() {
    return Array.from(this.element.querySelectorAll("input[type=radio]"))
  }
}
