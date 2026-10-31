import { Controller } from "@hotwired/stimulus"

// Asks an entry step's questions one at a time (situations/_question), so a step reads like a conversation rather than a
// form. It opens on the questions already answered plus the next one; a finished entry (open) shows them all, since
// people come back to change one thing. Continue (or Skip, while an optional answer is empty) brings up the next question
// and the step's drawing gives a small hop. Enter in a one-line answer does the same; Cmd/Ctrl+Enter in a textarea.
// Every field is in the form from the start, so drafts and saving don't change, and a required answer the browser
// stops on is brought into view. Without JavaScript every question shows.
export default class extends Controller {
  static targets = [ "question", "continue", "continueLabel", "drawing" ]
  static values = { open: Boolean }

  connect() {
    this.revealInvalid = this.revealInvalid.bind(this)
    this.element.addEventListener("invalid", this.revealInvalid, true)
    // After the draft controller on the same form has put back any unsaved answers, which count, and before paint.
    queueMicrotask(() => this.start())
  }

  start() {
    const last = this.questionTargets.length - 1
    const shown = this.openValue ? last : Math.min(last, Math.max(this.lastAnswered + 1, this.firstInvalid))
    this.questionTargets.forEach((question, i) => question.hidden = i > shown)
    this.update()
  }

  disconnect() {
    this.element.removeEventListener("invalid", this.revealInvalid, true)
  }

  next(event) {
    const question = event.target.closest("[data-conversation-target~=question]")
    const missing = Array.from(question.querySelectorAll("[required]")).find(field => !field.checkValidity())
    if (missing) return missing.reportValidity()

    this.reveal(this.questionTargets.indexOf(question) + 1)
  }

  // keydown.enter: moves on while there's a question still to come; otherwise Enter keeps its meaning (Next step).
  advance(event) {
    const field = event.target
    const question = field.closest("[data-conversation-target~=question]")
    const following = question && this.questionTargets[this.questionTargets.indexOf(question) + 1]
    if (event.defaultPrevented || !following?.hidden || field.matches("button, [type=checkbox], [type=radio]")) return
    if (field.matches("textarea") && !(event.metaKey || event.ctrlKey)) return

    event.preventDefault()
    this.next(event)
  }

  // Continue reads Skip while its question's optional answer is empty; only the last question showing has one.
  update() {
    this.questionTargets.forEach((question, i) => {
      const button = this.continueTargets.find(target => question.contains(target))
      if (!button) return

      const following = this.questionTargets[i + 1]
      button.hidden = !following?.hidden
      const label = this.continueLabelTargets.find(target => button.contains(target))
      label.textContent = this.answered(question) || question.querySelector("[required]") ? "Continue" : "Skip"
    })
  }

  reveal(index) {
    const question = this.questionTargets[index]
    if (!question?.hidden) return

    this.questionTargets.forEach((other, i) => { if (i < index) other.hidden = false })
    question.hidden = false
    question.classList.add("motion-safe:animate-question-in")
    this.update()
    this.hop()
    this.focus(question)
    question.scrollIntoView({ behavior: this.reducedMotion ? "auto" : "smooth", block: "start" })
  }

  // Into the new question's first field, so typing can start. Past-answer fields open their list on focus, which would cover
  // Skip, so for those the question itself takes focus and the list waits until the field is chosen.
  focus(question) {
    const field = question.querySelector("textarea, input:not([type=hidden], [type=range]), [type=range]")
    if (field && !field.matches("[role=combobox]")) return field.focus({ preventScroll: true })

    question.tabIndex = -1
    question.focus({ preventScroll: true })
  }

  // A required answer in a hidden question: bring it, and the questions before it, into view and point to it.
  revealInvalid(event) {
    const question = event.target.closest("[data-conversation-target~=question]")
    if (!question?.hidden) return

    const index = this.questionTargets.indexOf(question)
    this.questionTargets.forEach((other, i) => { if (i <= index) other.hidden = false })
    this.update()
    requestAnimationFrame(() => event.target.reportValidity())
  }

  hop() {
    if (!this.hasDrawingTarget || this.reducedMotion) return

    this.drawingTarget.animate([ { transform: "none" }, { transform: "translateY(-0.75rem) rotate(-2deg)" }, { transform: "none" } ],
      { duration: 600, easing: "cubic-bezier(0.3, 0.7, 0.4, 1)" })
  }

  // Whether a question has an answer. Hidden fields, the rating slider (its radios count) and a date that starts as now don't.
  answered(question) {
    return Array.from(question.querySelectorAll("input, textarea, select")).some(field => {
      if (field.matches("[type=hidden], [type=range], [data-conversation-prefilled]")) return false
      if (field.matches("[type=checkbox], [type=radio]")) return field.checked && field.value !== ""
      return field.value.trim() !== ""
    })
  }

  get lastAnswered() {
    return this.questionTargets.findLastIndex(question => this.answered(question))
  }

  get firstInvalid() {
    return this.questionTargets.findIndex(question => question.querySelector("[aria-invalid=true]"))
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
