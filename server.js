const express = require('express');
const app = express();

app.set('view engine', 'ejs');


app.get('/', (req, res) => {
    console.log(1111);
    // res.send("hey");
    res.render('index.ejs');

});


const userRouter = require('./routes/users');

app.use('/user', userRouter);



app.listen(3000);
