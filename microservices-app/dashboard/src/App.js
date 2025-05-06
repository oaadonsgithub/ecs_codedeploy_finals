// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

import React from 'react';
import Users from './components/Users';
import Products from './components/Products';
import Orders from './components/Orders';

function App() {
  return (
    <div style={{ padding: 20 }}>
      <h1>Microservices Dashboard</h1>
      <Users />
      <Products />
      <Orders />
    </div>
  );
}

export default App;
