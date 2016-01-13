require! \http
require! \querystring

data = JSON.stringify(require './post.json')

req = http.request({
  host: 'localhost',
  port: 3000,
  path: '/v1',
  method: 'POST',
  headers: {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(data)
  }
}, (res) ->
  res.setEncoding('utf8');
  res.on('data', (chunk) ->
    console.log('Response: ' + chunk);
  );
)

req.end(data);

set-interval ->, 1000