import { Controller } from "@hotwired/stimulus"

// One shared tooltip for every [data-tooltip] mark inside the controller's element.
// data-tooltip is the heading; data-tooltip-detail is an optional second line.
// Screen readers get the same text from each mark's sr-only label.
export default class extends Controller {
  static targets = [ "tip", "heading", "detail" ]

  show(event) {
    const mark = event.target.closest("[data-tooltip]")
    if (!mark || !this.element.contains(mark)) return

    this.headingTarget.textContent = mark.dataset.tooltip
    this.detailTarget.textContent = mark.dataset.tooltipDetail || ""
    this.detailTarget.hidden = !mark.dataset.tooltipDetail
    this.tipTarget.hidden = false
    this.position(mark)
  }

  hide(event) {
    const mark = event.target.closest("[data-tooltip]")
    if (mark && mark.contains(event.relatedTarget)) return

    this.dismiss()
  }

  dismiss() {
    this.tipTarget.hidden = true
  }

  position(mark) {
    const gap = 8
    const box = mark.getBoundingClientRect()
    const tip = this.tipTarget.getBoundingClientRect()
    const left = Math.min(Math.max(gap, box.left + box.width / 2 - tip.width / 2), window.innerWidth - tip.width - gap)
    const above = box.top - tip.height - gap
    const top = above >= gap ? above : box.bottom + gap

    this.tipTarget.style.left = `${left}px`
    this.tipTarget.style.top = `${top}px`
  }
}
