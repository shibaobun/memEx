// maintain user adjusted attributes, like textbox length on phoenix liveview
// update. https://github.com/phoenixframework/phoenix_live_view/issues/1011

export default {
  attrs () {
    if (this.el && this.el.getAttribute('data-attrs')) {
      return this.el.getAttribute('data-attrs').split(', ')
    } else {
      return []
    }
  },
  beforeUpdate () {
    if (this.el) {
      this.prevAttrs = this.attrs().map(name => [name, this.el.getAttribute(name)])
    }
  },
  updated () {
    if (this.el) {
      this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val))
    }
  }
}
