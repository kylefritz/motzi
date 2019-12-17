import React from 'react'

import User from './User'

export default function BakersChoice() {
  const { haventOrdered: users } = gon
  return (
    <>
      <h1>baker's choice js</h1>
      <table>
        <thead>
          <tr>
            <th>First Name</th>
            <th>Last Name</th>
            <th>Credits Remaining</th>
            <th>Breads per Week</th>
            <th>Tuesday Pickup?</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {users.map(u => <User key={u.id} {...u} />)}
        </tbody>
      </table>
    </>
  )
}
