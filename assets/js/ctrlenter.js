export default {
  addFormSubmit (context) {
    context.el.addEventListener('keydown', (e) => {
      if (e.ctrlKey && e.key === 'Enter') {
        context.el.dispatchEvent(
          new Event('submit', { bubbles: true, cancelable: true }))
      }
    })
  },
  mounted () { this.addFormSubmit(this) },
  updated () { this.addFormSubmit(this) }
}
