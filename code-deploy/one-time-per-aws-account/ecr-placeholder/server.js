const http = require('http')

http
  .createServer(function (req, res) {
    const msg = "I'm healthy"
    console.log(msg)
    res.writeHead(200, { 'Content-Type': 'text/html' })
    res.write(msg)
    res.end()
  })
  .listen(80, function () {
    console.log('Server started at port: 3000')
  })
