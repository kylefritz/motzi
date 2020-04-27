import React from "react";
import _ from "lodash";

export default function User({
  id: userId,
  name,
  hashid,
  credits,
  breadsPerWeek,
  onPickBread,
  menu,
}) {
  const handleClick = (itemId) => {
    onPickBread({ userId, itemId });
  };

  return (
    <tr>
      <td>
        <a href={`/admin/users/${userId}`}>{name}</a>
      </td>
      <td>{credits}</td>
      <td>{breadsPerWeek}</td>
      <td>
        {menu.items.map(({ id, name }) => (
          <button key={id} onClick={() => handleClick(id)}>
            {name}
          </button>
        ))}
      </td>
      <td>
        <a href={`/menu?uid=${hashid}`} target="_blank">
          Order with real menu
        </a>
      </td>
    </tr>
  );
}
