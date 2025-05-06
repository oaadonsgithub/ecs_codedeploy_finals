const express = require('express');
const axios = require('axios');
const app = express();
app.use(express.json());

const orders = [
  { id: 1001, userId: 1, productId: 101 }
];

app.get('/orders', async (req, res) => {
  const userResponse = await axios.get('http://localhost:3001/users');
  const productResponse = await axios.get('http://localhost:3002/products');

  const enrichedOrders = orders.map(order => {
    const user = userResponse.data.find(u => u.id === order.userId);
    const product = productResponse.data.find(p => p.id === order.productId);
    return { ...order, user, product };
  });

  res.json(enrichedOrders);
});

app.listen(3003, () => {
  console.log('Order service running on port 3003');
});
