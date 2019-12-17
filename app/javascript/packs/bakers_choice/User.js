import React from 'react';
import _ from 'lodash'

export default function User({ id: userId, firstName, lastName, tuesdayPickup, credits, breadsPerWeek, onPickBread, menu }) {
  const handleClick = (itemId) => {
    onPickBread({ userId, itemId })
  }

  return (
    <tr>
      <td>{firstName}</td>
      <td>{lastName}</td>
      <td>{credits}</td>
      <td>{breadsPerWeek}</td>
      <td>{tuesdayPickup ? "Tues" : "Thurs"}</td>
      <td>
        {menu.items.map(({ id, name }) =>
          <button key={id} onClick={() => handleClick(id)}>
            {name}
          </button>
        )}
      </td>
    </tr>
  )
}
