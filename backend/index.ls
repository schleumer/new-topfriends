require! \express
require! \path
require! \body-parser
require! \multer
require! \request
require! \fs
require! \crypto

session = require \express-session
RedisStore = require(\connect-redis)(session)
AWS = require \aws-sdk

s3 = new AWS.S3(computeChecksums: true)

s3.create-bucket { Bucket: 'schleumer-topfriends' }
  
store = (buffer, callback) ->
  hash = crypto.createHash 'sha512'
  hash.update(buffer)
  filename = hash.digest('hex') + ".png"
  params = { 
    Bucket: 'schleumer-topfriends'
    Key: filename
    Body: buffer
    ACL:'public-read'
    ContentType: 'image/png'
  }
  console.log 'storing object %s in bucket' filename
  eita = s3.put-object(params, (err, res) ->
    if not err
      console.log 'object %s stored in bucket' filename
    else
      console.log 'object %s was not stored in bucket' filename
    url = s3.getSignedUrl 'putObject', params.{Key, Bucket}
    callback(err, url.replace(/\?.*/, ''))
  )

app = express!

public-dir = path.join __dirname, "..", "public"
generated-files-dir = path.join public-dir, "generated-files"


allow-cors = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin' '*'
  res.header 'Access-Control-Allow-Methods' 'GET,PUT,POST,DELETE'
  res.header 'Access-Control-Allow-Headers' 'Content-Type'
  next!

app.use body-parser.json limit: '50mb'
app.use body-parser.urlencoded extended: yes, limit: '50mb'
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
    .get("http://graph.facebook.com#{req.query.path}")
    .pipe(res)

app.post "/base64-proxy" (req, res) ->
  console.log '/base64-proxy accessed'
  buffer = new Buffer(req.body.image.replace(/^data:(.*?);base64,/,''), 'base64')
  store buffer, (err, url) ->
    if err
      console.log err
      res.send-status 500
    else
      res.send url
    
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
