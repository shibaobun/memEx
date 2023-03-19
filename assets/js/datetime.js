export default {
  displayDateTime (el) {
    const date =
      Intl.DateTimeFormat([], { dateStyle: 'short', timeStyle: 'long' })
        .format(new Date(el.dateTime))

    el.innerText = date
  },
  mounted () { this.displayDateTime(this.el) },
  updated () { this.displayDateTime(this.el) }
}
