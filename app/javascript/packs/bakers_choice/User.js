import React from 'react';

export default function User({ firstName, lastName, tuesdayPickup, credits, breadsPerWeek }) {
  return (
    <tr>
      <td>{firstName}</td>
      <td>{lastName}</td>
      <td>{credits}</td>
      <td>{breadsPerWeek}</td>
      <td>{tuesdayPickup ? "Tues" : "Thurs"}</td>
    </tr>
  )
}
