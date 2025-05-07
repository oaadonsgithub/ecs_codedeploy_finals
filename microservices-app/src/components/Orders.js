// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Orders = () => {
  const [orders, setOrders] = useState([]);

  useEffect(() => {
    axios.get(`${process.env.REACT_APP_ORDER_API}/orders`)
      .then(res => setOrders(res.data))
      .catch(err => console.error(err));
  }, []);

  return (
    <div className="mb-4">
      <h2>Orders</h2>
      <ul className="list-group">
        {orders.map(order => (
          <li key={order.id} className="list-group-item">
            Order #{order.id}: {order.user?.name} ordered {order.product?.name}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default Orders;
