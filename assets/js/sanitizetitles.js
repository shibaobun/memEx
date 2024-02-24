export default {
  SanitizeTitles (context) {
    context.el.addEventListener('keyup', (e) => {
      e.target.value = e.target.value
        .replace(' ', '-')
        .replace(/[^a-zA-Z0-9-]/, '')
    })
  },
  mounted () { this.SanitizeTitles(this) }
}
