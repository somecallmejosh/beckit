import { Controller } from "@hotwired/stimulus"

// Makes a table of [data-tooltip] cells one tab stop; arrow keys, Home and End move between cells.
// Focus shows the shared tooltip (the tooltip controller listens for focusin/focusout).
export default class extends Controller {
  connect() {
    this.cells.forEach((cell, i) => cell.tabIndex = i === 0 ? 0 : -1)
  }

  move(event) {
    const moves = { ArrowLeft: [ 0, -1 ], ArrowRight: [ 0, 1 ], ArrowUp: [ -1, 0 ], ArrowDown: [ 1, 0 ] }
    const grid = this.grid
    const row = grid.findIndex(cells => cells.includes(event.target))
    if (row < 0) return

    const col = grid[row].indexOf(event.target)
    let [ r, c ] = [ row, col ]
    if (event.key in moves) {
      r = Math.min(Math.max(row + moves[event.key][0], 0), grid.length - 1)
      c = Math.min(Math.max(col + moves[event.key][1], 0), grid[r].length - 1)
    } else if (event.key === "Home") {
      c = 0
    } else if (event.key === "End") {
      c = grid[r].length - 1
    } else {
      return
    }

    event.preventDefault()
    event.target.tabIndex = -1
    grid[r][c].tabIndex = 0
    grid[r][c].focus()
  }

  get cells() {
    return [ ...this.element.querySelectorAll("td[data-tooltip]") ]
  }

  get grid() {
    return [ ...this.element.tBodies[0].rows ].map(row => [ ...row.querySelectorAll("td[data-tooltip]") ])
  }
}
