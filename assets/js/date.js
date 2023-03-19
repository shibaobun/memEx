export default {
  displayDate (el) {
    const date =
      Intl.DateTimeFormat([], { timeZone: 'Etc/UTC', dateStyle: 'short' })
        .format(new Date(el.dateTime))

    el.innerText = date
  },
  mounted () { this.displayDate(this.el) },
  updated () { this.displayDate(this.el) }
}
