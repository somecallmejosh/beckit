import { Controller } from "@hotwired/stimulus"

const OUTPUT_SIZE = 512
const NUDGE = 8

// Square crop for a round avatar: drag or arrow keys to pan, slider to zoom.
// "Use photo" swaps the chosen file for a 512px crop; nothing uploads until the form is saved.
// Without JavaScript the plain file input still works and the server center-crops.
export default class extends Controller {
  static targets = [ "input", "stage", "viewport", "image", "zoom", "preview", "current", "remove" ]

  disconnect() {
    this.revoke()
    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
  }

  load() {
    const file = this.inputTarget.files[0]
    this.revoke()
    if (!file || !file.type.startsWith("image/")) return this.close()

    this.sourceUrl = URL.createObjectURL(file)
    this.imageTarget.onload = () => this.start()
    this.imageTarget.onerror = () => this.close()
    this.imageTarget.src = this.sourceUrl
  }

  start() {
    this.stageTarget.hidden = false
    this.size = this.viewportTarget.clientWidth
    const { naturalWidth: w, naturalHeight: h } = this.imageTarget
    this.baseScale = Math.max(this.size / w, this.size / h)
    this.zoomTarget.value = 1
    this.scale = this.baseScale
    this.x = (this.size - w * this.scale) / 2
    this.y = (this.size - h * this.scale) / 2
    this.render()
    this.viewportTarget.focus()
  }

  zoom() {
    const next = this.baseScale * Number(this.zoomTarget.value)
    const center = this.size / 2
    this.x = center - ((center - this.x) / this.scale) * next
    this.y = center - ((center - this.y) / this.scale) * next
    this.scale = next
    this.render()
  }

  startDrag(event) {
    this.dragging = { x: event.clientX - this.x, y: event.clientY - this.y }
    this.viewportTarget.setPointerCapture(event.pointerId)
  }

  drag(event) {
    if (!this.dragging) return
    this.x = event.clientX - this.dragging.x
    this.y = event.clientY - this.dragging.y
    this.render()
  }

  endDrag() {
    this.dragging = null
  }

  nudge(event) {
    const moves = { ArrowLeft: [ NUDGE, 0 ], ArrowRight: [ -NUDGE, 0 ], ArrowUp: [ 0, NUDGE ], ArrowDown: [ 0, -NUDGE ] }
    const move = moves[event.key]
    if (!move) return
    event.preventDefault()
    this.x += move[0]
    this.y += move[1]
    this.render()
  }

  // Keeps the image covering the whole square, then positions it.
  render() {
    const width = this.imageTarget.naturalWidth * this.scale
    const height = this.imageTarget.naturalHeight * this.scale
    this.x = Math.min(0, Math.max(this.size - width, this.x))
    this.y = Math.min(0, Math.max(this.size - height, this.y))
    Object.assign(this.imageTarget.style, { width: `${width}px`, height: `${height}px`, transform: `translate(${this.x}px, ${this.y}px)` })
  }

  async apply() {
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = OUTPUT_SIZE
    const side = this.size / this.scale
    canvas.getContext("2d").drawImage(this.imageTarget, -this.x / this.scale, -this.y / this.scale, side, side, 0, 0, OUTPUT_SIZE, OUTPUT_SIZE)

    let blob = await new Promise(resolve => canvas.toBlob(resolve, "image/webp", 0.9))
    if (!blob || blob.type !== "image/webp") blob = await new Promise(resolve => canvas.toBlob(resolve, "image/jpeg", 0.9))
    const extension = blob.type === "image/webp" ? "webp" : "jpg"

    const transfer = new DataTransfer()
    transfer.items.add(new File([ blob ], `avatar.${extension}`, { type: blob.type }))
    this.inputTarget.files = transfer.files

    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
    this.previewUrl = URL.createObjectURL(blob)
    this.previewTarget.src = this.previewUrl
    this.previewTarget.hidden = false
    this.currentTarget.hidden = true
    if (this.hasRemoveTarget) this.removeTarget.checked = false
    this.close()
  }

  // Clears the selection entirely, including any crop applied earlier.
  cancel() {
    this.inputTarget.value = ""
    this.previewTarget.hidden = true
    this.currentTarget.hidden = false
    this.close()
  }

  close() {
    this.stageTarget.hidden = true
    this.dragging = null
  }

  revoke() {
    if (this.sourceUrl) URL.revokeObjectURL(this.sourceUrl)
    this.sourceUrl = null
  }
}
