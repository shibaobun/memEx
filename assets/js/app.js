// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import '../css/app.scss'
import '@fontsource/nunito-sans'

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import topbar from 'topbar'
import Date from './date'
import DateTime from './datetime'

const csrfTokenElement = document.querySelector("meta[name='csrf-token']")
let csrfToken
if (csrfTokenElement) { csrfToken = csrfTokenElement.getAttribute('content') }
const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { Date, DateTime }
})

// Show progress bar on live navigation and form submits
topbar.config({ barThickness: 1, barColors: { 0: '#fff' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', info => topbar.show())
window.addEventListener('phx:page-loading-stop', info => topbar.hide())
window.addEventListener('submit', info => topbar.show())
window.addEventListener('beforeunload', info => topbar.show())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Copy to clipboard
window.addEventListener('memex:clipcopy', (event) => {
  if ('clipboard' in navigator) {
    const text = event.target.textContent
    navigator.clipboard.writeText(text)
  } else {
    window.alert('Sorry, your browser does not support clipboard copy.')
  }
})
