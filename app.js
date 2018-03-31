const http = require('http')

http.createServer((req, res) => {
    res.end('jenkins t2')
}).listen(3000, () => {
    console.log('running on port 3000');
})