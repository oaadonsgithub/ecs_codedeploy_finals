// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

import React, { useEffect, useState } from 'react';
import axios from 'axios';

const Products = () => {
  const [products, setProducts] = useState([]);

  useEffect(() => {
    axios.get('http://localhost:3002/products')
      .then(res => setProducts(res.data))
      .catch(err => console.error('Error fetching products:', err));
  }, []);

  return (
    <div>
      <h2>Products</h2>
      <pre>{JSON.stringify(products, null, 2)}</pre>
    </div>
  );
};

export default Products;
