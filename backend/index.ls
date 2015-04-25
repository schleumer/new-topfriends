require! 'express'
require! 'path'

app = express!

app.use(express.static(path.join(__dirname, '..', 'public')));

app.get '/', (req, res) -> res.redirect 'index.html'
app.post '/do', (req, res) -> res.send(req.body)

server = app.listen 3000, ->
  host = server.address!.address
  port = server.address!.port
  console.log 'Example app listening at http://%s:%s', host, port