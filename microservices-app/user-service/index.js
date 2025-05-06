const express = require('express');
const app = express();
app.use(express.json());

const users = [{ id: 1, name: 'Alice' }];

app.get('/users', (req, res) => {
  res.json(users);
});

app.listen(3001, () => {
  console.log('User service running on port 3001');
});
