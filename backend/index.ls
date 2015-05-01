require! \express
require! \path
require! \body-parser
require! \multer
require! \request
require! \fs
require! \crypto

{ each, first, last } = require \prelude-ls

session = require \express-session
RedisStore = require(\connect-redis)(session)
AWS = require \aws-sdk

s3 = new AWS.S3 compute-checksums: true
s3.create-bucket Bucket: \schleumer-topfriends

store = (buffer, callback) ->
  let hash = crypto.create-hash \sha512
    hash.update buffer
    filename = (hash.digest \hex) + \.png
    params =
      Bucket: \schleumer-topfriends
      Key: filename
      Body: buffer
      ACL: \public-read
      ContentType: \image/png

    console.log 'storing object %s in bucket' filename

    # WTF is eita?
    eita = s3.put-object params, (err, res) ->
      console.log "object %s #{'was not ' if err}stored in bucket" filename
      callback (s3.get-signed-url \putObject params.{Key, Bucket}) - /\?.*/

app = express!

public-dir = path.join __dirname \.. \public
generated-files-dir = path.join public-dir \generated-files

Unit (x) -> { run: x! }

allow-cors = (req, res, next) ->
  [ <[ Access-Control-Allow-Origin * ]>
    <[ Access-Control-Allow-Methods GET,PUT,POST,DELETE ]>
    <[ Access-Control-Allow-Headers Content-Type ]> ]
  |> each (pair) -> res.header (first pair) (last pair)
  Unit next .run

app.use body-parser.json limit: \50mb
app.use body-parser.urlencoded extended: yes, limit: \50mb
app.use multer!
app.use allow-cors

app.use session {
  resave: no
  save-uninitialized: yes
  store: new RedisStore {}
  secret: process.env[\STORAGE_SECRET] or "its a *** secret"
}

app.use express.static public-dir

app.get "/" (req, res) -> res.redirect \index.html

app.get "/facebook-proxy" (req, res) ->
  console.log "/facebook-proxy proxy'd %s" req.query.path
  # TODO: WTF???
  request
    .get "http://graph.facebook.com#{req.query.path}"
    .pipe res

app.post "/base64-proxy" (req, res) ->
  console.log '/base64-proxy accessed'
  buffer = new Buffer req.body.image - /^data:(.*?);base64,/, \base64
  store buffer, (err, url) ->
    | err => do ~>
      console.log err
      res.send-status 500
    | _   => res.send url
    
  #target-file = 'image.jpg'
  #target-path = path.join generated-files-dir, target-file
  #stream = fs.create-write-stream(target-path)
  #stream.write buffer
  #stream.end!
  #stream.close!
  #res.send { image: null }

app.post "/do" (req, res) ->
  req.session <<< {
    data: req.body.data |> JSON.parse
    next: "/topchat"
  }
  res.redirect "/"

app.get "/get" (req, res) ->
  #res.send require "./test.json"
  res.send req.session.{data, next}

app.use (req,res) ->
    res.redirect('/index.html')

server = app.listen (process.env['PORT'] or 3000), ->
  host = server.address!address
  port = server.address!port
  console.log 'Example app listening at http://%s:%s' host, port
