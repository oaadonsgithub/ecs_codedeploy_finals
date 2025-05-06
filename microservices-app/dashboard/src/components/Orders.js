// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

import React, { useEffect, useState } from 'react';
import axios from 'axios';

const Orders = () => {
  const [orders, setOrders] = useState([]);

  useEffect(() => {
    axios.get('http://localhost:3003/orders')
      .then(res => setOrders(res.data))
      .catch(err => console.error('Error fetching orders:', err));
  }, []);

  return (
    <div>
      <h2>Orders</h2>
      <pre>{JSON.stringify(orders, null, 2)}</pre>
    </div>
  );
};

export default Orders;
