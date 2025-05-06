// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

import React, { useEffect, useState } from 'react';
import axios from 'axios';

const Users = () => {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    axios.get('http://localhost:3001/users')
      .then(res => setUsers(res.data));
  }, []);

  return (
    <div>
      <h2>Users</h2>
      <pre>{JSON.stringify(users, null, 2)}</pre>
    </div>
  );
};

export default Users;
