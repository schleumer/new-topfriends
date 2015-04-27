require! 'express'
require! 'path'
require! 'body-parser'
require! 'multer'

session = require 'express-session'
RedisStore = require('connect-redis')(session)

app = express!

app.use(body-parser.json!)
app.use(body-parser.urlencoded { extended: true })
app.use(multer!)

app.use(session({ 
  resave: false,
  saveUninitialized: true,
  store: new RedisStore({}),
  secret: process.env['STORAGE_SECRET'] || 'its a *** secret' 
}))

app.use(express.static(path.join(__dirname, '..', 'public')));

app.get '/', (req, res) -> res.redirect 'index.html'
app.post '/do', (req, res) -> 
  req.session <<< {
    data: req.body.data |> JSON.parse,
    next: '/topchat'
  }
  res.redirect '/'

app.get '/get', (req, res) -> res.send req.session.{data, next}

server = app.listen 3000, ->
  host = server.address!.address
  port = server.address!.port
  console.log 'Example app listening at http://%s:%s', host, port