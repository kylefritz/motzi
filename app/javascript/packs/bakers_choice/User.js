import React from 'react';
import _ from 'lodash'

export default function User({ firstName, lastName, tuesdayPickup, credits, breadsPerWeek }) {
  const menuItems = gon.menu.filter(({ name }) => !name.match(/skip/ig))
  return (
    <tr>
      <td>{firstName}</td>
      <td>{lastName}</td>
      <td>{credits}</td>
      <td>{breadsPerWeek}</td>
      <td>{tuesdayPickup ? "Tues" : "Thurs"}</td>
      <td>Asign Bread</td>
    </tr>
  )
}
