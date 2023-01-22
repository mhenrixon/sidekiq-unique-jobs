import { Turbo } from "@hotwired/turbo-rails"
import "@rails/request.js"
import "controllers"
import mrujs from "mrujs"

mrujs.start()

// Make accessible for Electron and Mobile adapters
window.Turbo = Turbo
