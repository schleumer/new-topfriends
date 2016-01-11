require! \express
require! \path
require! \body-parser
require! \multer
require! \request
require! \fs
require! \crypto
require! \jade
require! \phantom-cluster

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

    s3.put-object params, (err, res) ->
      console.log "object %s #{'was not ' if err}stored in bucket" filename
      callback (s3.get-signed-url \putObject params.{Key, Bucket}) - /\?.*/

app = express!

public-dir = path.join __dirname, \.. \public
generated-files-dir = path.join public-dir, \generated-files

Unit = (x) -> { run: x! }

allow-cors = (req, res, next) ->
  [ <[ Access-Control-Allow-Origin * ]>
    <[ Access-Control-Allow-Methods GET,PUT,POST,DELETE ]>
    <[ Access-Control-Allow-Headers Content-Type ]> ]
  |> each (pair) ->
    # return res.header(first(pair)(last(pair)));
    res.header (first pair), (last pair)
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

app.post "/" (req, res) ->
  console.log(req.body)
  fn = jade.compile (fs.read-file-sync './image-templates/default.jade'), {}
  console.log(fn({}))
  res.send 'upa lele'

app.use (req,res) ->
  res.redirect '/'

server = app.listen (process.env['PORT'] or 3000), ->
  host = server.address!address
  port = server.address!port
  console.log 'image-service listening at http://%s:%s' host, port
