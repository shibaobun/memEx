export default {
  SanitizeTags (context) {
    context.el.addEventListener('keyup', (e) => {
      e.target.value = e.target.value
        .replace(' ', ',')
        .replace(',,', ',')
        .replace(/[^a-zA-Z0-9,]/, '')
    })
  },
  mounted () { this.SanitizeTags(this) }
}
