import React, { useState } from 'react'
import axios from 'axios'

import User from './User'

export default function BakersChoice() {
  const { haventOrdered, menu } = gon
  const [users, setUsers] = useState(haventOrdered)

  const handlePickBread = ({ userId, itemId }) => {
    const order = { userId, itemId }
    console.log("create order", order, 'for menu:', menu.id)
    axios.post(`/admin/menus/bakers_choice.json`, order).then(({ data: users }) => {
      setUsers(users)
    })
  }

  return (
    <table>
      <thead>
        <tr>
          <th>First Name</th>
          <th>Last Name</th>
          <th>Credits Remaining</th>
          <th>Breads per Week</th>
          <th>Tuesday Pickup?</th>
          <th>Asign Bread</th>
        </tr>
      </thead>
      <tbody>
        {users.map(u => <User key={u.id} {...u} menu={menu} onPickBread={handlePickBread} />)}
      </tbody>
    </table>
  )
}
