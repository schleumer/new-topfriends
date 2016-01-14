require! \express
require! \path
require! \body-parser
require! \multer
require! \request
require! \fs
require! \crypto
require! \jade
require! \util

Q = require 'bluebird'
Queue = require 'promise-queue'
Queue.configure Promise

spawn = require('child_process').spawn;

get-style = (style) ->
  fs.read-file-sync (path.join __dirname, 'image-styles', style + '.css')

rand = ->
  (resolve, reject) <-! new Promise!
  crypto.randomBytes(48, (ex, buf) ->
    console.log(buf.toString('hex'))
    resolve(buf.toString('hex'))
  );

capture = (url, output) ->
  ->
    (resolve, reject) <-! new Promise!
    execution = spawn("phantomjs", ['--disk-cache=true', (path.join __dirname, 'rasterize.js'), url, output])
    
    # execution.stdout.on('data', (data) ->
    #   console.log('stdout: ' + data)
    # )

    # execution.stderr.on('data', (data) ->
    #   console.log('stderr: ' + data)
    # )
    
    execution.on 'exit', (code) ->
      resolve output if code === 0
      reject code if code !== 0

maxConcurrent = 3
maxQueue = Infinity
queue = new Queue(maxConcurrent, maxQueue)

{ each, first, last } = require \prelude-ls

session = require \express-session
RedisStore = require(\connect-redis)(session)
AWS = require \aws-sdk

s3 = new AWS.S3 compute-checksums: true
s3.create-bucket Bucket: \schleumer-topfriends

store = (buffer) ->
  (resolve, reject) <- new Promise!
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
      console.log "object %s #{if err then 'was not ' else ''}stored in bucket" filename
      resolve (s3.get-signed-url \putObject params.{Key, Bucket}) - /\?.*/

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

class Drawer
  cache: []
  real-render: (file, variables) ->
    try
      content = @cache[file]({...variables, get-style})
    catch ex
      console.log ex

    delete @cache[file]
    rand!
      .then (x) ->
        [x, path.join __dirname, '..', 'template-cache', 'test' + '.html']
      .then ([x, file-path]) ->
        fs.write-file-sync file-path, content
        [x, file-path]
  
  pre-render: (file, variables) ->
    (resolve, reject) <~! new Promise!
    fn = jade.compile (fs.read-file-sync file), {
      pretty: yes
    }
    @cache[file] = fn
    resolve @render(file, variables)

  render: (file, variables = {}) ->
    return @real-render file, variables if @cache[file]
    return @pre-render file, variables if not @cache[file]

drawer = new Drawer

langs = {
  "pt-br": {
    "header": "Esses são os amigos com quem mais converso",
    "message_counter": ["<b>%s</b> %s", ["mensagem", "mensagens"], "nenhuma mensagem"],
    "footer": "Faça o seu também! Acesse: <a href=\"javascript:;\">topfriends.biz</a> ou <a href=\"javascript:;\">topamig.us</a>."
  }
}
class MonkeyPatchLang
  strings: {}
  (lang) ->
    @strings = langs[lang]
  get: (string, ...params) ->
    util.format(@strings[string], ...params)
  getPlural: (number, string, ...params) ->
    [str, [singular, plural], none = ""] = @strings[string]
    return util.format(str, number, plural, ...params) if number > 1
    return util.format(str, number, singular, ...params) if number == 1
    return none if number < 1


app.get '/upa' (req, res) ->
  drawer.render './image-templates/default.jade'
    .then ([x, file-path]) ->
      is-win = /^win/.test process.platform
      image-path = path.join __dirname, '..', 'image-cache', x + '.png'
      if is-win
        queue.add (capture 'file:///' + file-path, image-path)
      else
        queue.add (capture 'file://' + file-path, image-path)
    .then (code) ->
      res.send code.to-string!

app.post "/v1" (req, res) ->
  console.log("image requested")
  lang = new MonkeyPatchLang(req.query.lang || "pt-br")
  column-size = (req.query.column-size || 6).to-string!
  max-friends = (req.query.max-friends || 10).to-string!

  if (["6", "4", "3"].index-of column-size) < 0
    column-size = "6"

  if (["25", "20", "15", "10", "5"].index-of max-friends) < 0
    max-friends = "10"

  max-friends = parse-int max-friends
  friends = req.body

  if Array.is-array friends
    friends = friends.slice 0, max-friends
  else
    res.send 500
    return


  drawer.render './image-templates/default.jade', { 
    data: friends,
    str: lang.get.bind(lang),
    plural: lang.getPlural.bind(lang),
    column-size: column-size
    width: (12 / column-size) * 280
  }
    .then ([x, file-path]) -> 
      is-win = /^win/.test process.platform
      image-path = path.join __dirname, '..', 'image-cache', x + '.png'
      if is-win
        queue.add (capture 'file:///' + file-path, image-path)
      else
        queue.add (capture 'file://' + file-path, image-path)
    .then (output-path) ->
      store (fs.read-file-sync output-path)
    .then (image-url) ->
      console.log "image generated"
      res.send image-url

app.use (req,res) ->
  console.log(req)
  res.redirect '/'

server = app.listen (process.env['PORT'] or 3000), ->
  host = server.address!address
  port = server.address!port
  console.log 'image-service listening at http://%s:%s' host, port
