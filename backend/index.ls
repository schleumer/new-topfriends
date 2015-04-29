require! \express
require! \path
require! \body-parser
require! \multer

session = require \express-session
RedisStore = require(\connect-redis)(session)

app = express!

allow-cors = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin' '*'
  res.header 'Access-Control-Allow-Methods' 'GET,PUT,POST,DELETE'
  res.header 'Access-Control-Allow-Headers' 'Content-Type'
  next!

app.use body-parser.json!
app.use body-parser.urlencoded extended: yes
app.use multer!
app.use allow-cors

app.use session {
  resave: no
  save-uninitialized: yes
  store: new RedisStore {}
  secret: process.env[\STORAGE_SECRET] or "its a *** secret"
}

app.use express.static path.join __dirname, ".." \public

app.get "/" (req, res) -> res.redirect \index.html

app.post "/do" (req, res) ->
  req.session <<< {
    data: req.body.data |> JSON.parse
    next: "/topchat"
  }
  res.redirect "/"

app.get "/get" (req, res) ->
  #res.send require "./test.json"
  res.send req.session.{data, next}

server = app.listen 3000 ->
  host = server.address!address
  port = server.address!port
  console.log 'Example app listening at http://%s:%s' host, port