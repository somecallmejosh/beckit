import { Controller } from "@hotwired/stimulus"

// A text field that offers the user's past answers (an ARIA combobox with a listbox).
// Typing filters the list; anything typed is still a valid answer, so a new one is saved like any other
// and offered next time. Choosing an option fires change, so the draft controller keeps it.
export default class extends Controller {
  static targets = [ "input", "listbox", "option" ]

  // On focus or click: an answer already chosen shows every option, so it's easy to switch.
  open() {
    const value = this.query
    this.show(this.optionTargets.some(option => this.label(option) == value) ? "" : value)
  }

  filter() {
    this.show(this.query)
  }

  close() {
    this.activate(null)
    this.listboxTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
  }

  navigate(event) {
    const expanded = !this.listboxTarget.hidden

    switch (event.key) {
      case "ArrowDown":
      case "ArrowUp":
        event.preventDefault()
        expanded ? this.move(event.key == "ArrowDown" ? 1 : -1) : this.open()
        break
      case "Enter":
        // Only when an option is highlighted; otherwise Enter submits the form as usual.
        if (expanded && this.active) {
          event.preventDefault()
          this.choose(this.active)
        }
        break
      case "Escape":
        if (expanded) {
          event.preventDefault()
          this.close()
        }
        break
    }
  }

  // Options listen on mousedown with :prevent, so the input keeps focus and doesn't blur first.
  pick(event) {
    this.choose(event.currentTarget)
  }

  choose(option) {
    this.inputTarget.value = option.textContent
    this.close()
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  show(query) {
    this.optionTargets.forEach(option => option.hidden = !this.label(option).includes(query))
    this.activate(null)

    const any = this.visibleOptions.length > 0
    this.listboxTarget.hidden = !any
    this.inputTarget.setAttribute("aria-expanded", String(any))
  }

  move(step) {
    const options = this.visibleOptions
    const current = options.indexOf(this.active)
    const index = current < 0 ? (step > 0 ? 0 : options.length - 1) : (current + step + options.length) % options.length
    this.activate(options[index])
  }

  activate(option) {
    this.optionTargets.forEach(other => other.setAttribute("aria-selected", String(other == option)))
    this.active = option

    if (option) {
      this.inputTarget.setAttribute("aria-activedescendant", option.id)
      option.scrollIntoView({ block: "nearest" })
    } else {
      this.inputTarget.removeAttribute("aria-activedescendant")
    }
  }

  label(option) {
    return option.textContent.toLowerCase()
  }

  get query() {
    return this.inputTarget.value.trim().toLowerCase()
  }

  get visibleOptions() {
    return this.optionTargets.filter(option => !option.hidden)
  }
}
