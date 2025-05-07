
// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Products = () => {
  const [search, setSearch] = useState('');
  const [products, setProducts] = useState([]);

  useEffect(() => {
    axios.get(`${process.env.REACT_APP_PRODUCT_API}/products`)
      .then(res => setProducts(res.data))
      .catch(err => console.error(err));
  }, []);

  const filtered = products.filter(product =>
    product.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="mb-4">
      <h2>Products</h2>
      <input className="form-control mb-2" placeholder="Search products..." value={search} onChange={e => setSearch(e.target.value)} />
      <ul className="list-group">
        {filtered.map(p => (
          <li key={p.id} className="list-group-item">{p.name} (ID: {p.id})</li>
        ))}
      </ul>
    </div>
  );
};

export default Products;
