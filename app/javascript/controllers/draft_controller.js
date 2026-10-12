import { Controller } from "@hotwired/stimulus"

// Keeps an unsaved entry in sessionStorage so a reload, misclick or back button doesn't lose it.
// sessionStorage (not localStorage) so sensitive text doesn't outlive the tab on a shared device.
// Warns before closing the tab with unsaved changes; cleared on a successful save or Cancel.
export default class extends Controller {
  static targets = [ "notice" ]
  static values = { key: String }

  connect() {
    this.initial = this.serialize()
    this.warn = this.warn.bind(this)
    window.addEventListener("beforeunload", this.warn)

    const draft = sessionStorage.getItem(this.keyValue)
    if (draft && draft !== this.initial) {
      this.apply(draft)
      this.noticeTarget.hidden = false
    }
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.warn)
  }

  save() {
    if (this.cleared) return

    const current = this.serialize()
    if (current === this.initial) {
      sessionStorage.removeItem(this.keyValue)
    } else {
      sessionStorage.setItem(this.keyValue, current)
    }
  }

  // turbo:submit-end: a failed save re-renders the form, so the draft stays until one succeeds.
  submitted(event) {
    if (event.detail.success) this.clear()
  }

  discard() {
    this.apply(this.initial)
    sessionStorage.removeItem(this.keyValue)
    this.noticeTarget.hidden = true
  }

  // Leaving the form: the focused field can still fire "change" as the page swaps, so stop saving too.
  clear() {
    this.cleared = true
    sessionStorage.removeItem(this.keyValue)
    window.removeEventListener("beforeunload", this.warn)
  }

  warn(event) {
    if (this.serialize() !== this.initial) event.preventDefault()
  }

  serialize() {
    const data = new FormData(this.element)
    data.delete("authenticity_token")
    return JSON.stringify([ ...data.entries() ])
  }

  apply(json) {
    const entries = JSON.parse(json)
    const values = name => entries.filter(([ key ]) => key === name).map(([ , value ]) => value)

    for (const field of this.element.elements) {
      if (!field.name || field.type === "hidden" || field.type === "submit") continue

      if (field.type === "checkbox" || field.type === "radio") {
        field.checked = values(field.name).includes(field.value)
      } else {
        field.value = values(field.name)[0] ?? ""
      }
    }
  }
}
