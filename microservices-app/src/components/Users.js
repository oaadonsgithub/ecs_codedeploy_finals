// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0


import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Users = () => {
  const [search, setSearch] = useState('');
  const [users, setUsers] = useState([]);

  useEffect(() => {
    axios.get(`${process.env.REACT_APP_USER_API}/users`)
      .then(res => setUsers(res.data))
      .catch(err => console.error(err));
  }, []);

  const filtered = users.filter(user =>
    user.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="mb-4">
      <h2>Users</h2>
      <input className="form-control mb-2" placeholder="Search users..." value={search} onChange={e => setSearch(e.target.value)} />
      <ul className="list-group">
        {filtered.map(u => (
          <li key={u.id} className="list-group-item">{u.name} (ID: {u.id})</li>
        ))}
      </ul>
    </div>
  );
};

export default Users;
