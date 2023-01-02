var express = require('express');
var my_sql = require('mysql2');
var bodyParser = require('body-parser');
const { request } = require('express');
var app = express();
var port = 3000;

// Allows use of ExpressJS template
app.set('view engine', 'ejs');
// Allows extraction of information from POST request
app.use(bodyParser.urlencoded({extended: true}));
app.use(express.static(__dirname + '/public'));

var connection = my_sql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'Bulgogi4957$',
    database: 'join_us'
});

app.get('/', function(req,res) {
    // Find count of users in db
    var q = 'SELECT COUNT(*) AS user_count FROM users';
    connection.query(q, function(err,results){
        if (err) throw err;
        var user_count = results[0].user_count;
        //res.send('Welcome to the home page! We have ' + user_count + ' users.');
        // Use res.render when adding ejs instead of res.send
        res.render('home', {data: user_count});
    });
})

app.post("/register", function(req,res) {
    var person = {
        email: req.body.email
    };
    connection.query('INSERT INTO users SET ?', person, function(error,results,field) {
        if (error) throw error;
        res.redirect('/');
        //res.send('Thanks for joining our waitlist!');
    });
    console.log('Post request sent to /register. Email is ' + req.body.email);
});

app.get('/joke', function(req,res) {
    var joke = 'What do you call a dog that does magic tricks? A labracadabra!';
    res.send(joke);
});

app.get('/random_num', function(req,res) {
    // Return a random number between 1 and 10
    var num = Math.floor(Math.random() * 10) + 1;
    res.send('Your lucky number is ' + num);
});

app.listen(port, function() {
    console.log('Server running on ' + port);
});

