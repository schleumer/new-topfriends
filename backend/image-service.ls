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

capture = (url) ->
  ->
    (resolve, reject) <-! new Promise!
    execution = spawn("phantomjs", ['--disk-cache=true', (path.join __dirname, 'rasterize.js'), url, 'lmao.png'])
    
    # execution.stdout.on('data', (data) ->
    #   console.log('stdout: ' + data)
    # )

    # execution.stderr.on('data', (data) ->
    #   console.log('stderr: ' + data)
    # )
    
    execution.on 'exit', (code) ->
      resolve code if code === 0
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
      queue.add (capture 'file://' + file-path, x)
    .then (code) ->
      res.send code.to-string!

app.post "/v1" (req, res) ->
  lang = new MonkeyPatchLang(req.query.lang || "pt-br")
  columnSize = req.query.columnSize || 6

  drawer.render './image-templates/default.jade', { 
    data: req.body,
    str: lang.get.bind(lang),
    plural: lang.getPlural.bind(lang),
    columnSize: columnSize
    width: (12 / columnSize) * 280
  }
    .then ([x, file-path]) -> 
      queue.add (capture 'file://' + file-path, x)
    .then (code) ->
      console.log "image generated"
      res.send "upa lele #{code}"

app.use (req,res) ->
  res.redirect '/'

server = app.listen (process.env['PORT'] or 3000), ->
  host = server.address!address
  port = server.address!port
  console.log 'image-service listening at http://%s:%s' host, port
