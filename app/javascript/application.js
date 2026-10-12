// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// Turbo marks the page as force-reloaded when a frame with data-turbo-action="advance" updates the URL,
// but never reloads or clears the flag, so every later visit skips scrolling to the top (the Insights panel
// is such a frame). A real force reload replaces the page, so clearing the flag after each visit is safe.
document.addEventListener("turbo:load", () => { Turbo.session.view.forceReloaded = false })
