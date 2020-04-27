import React, { useState } from "react";
import axios from "axios";

import User from "./User";

export default function BakersChoice() {
  const { haventOrdered, menu } = gon;
  const [users, setUsers] = useState(haventOrdered);
  const [day, setDay] = useState("Thursday");

  const handlePickBread = ({ userId, itemId }) => {
    const order = { userId, itemId, day };
    console.log("create order", order, "for menu:", menu.id);
    axios
      .post(`/admin/menus/bakers_choice.json`, order)
      .then(({ data: users }) => {
        setUsers(users);
      });
  };

  return (
    <>
      <h4>
        Pickup day assigning for:{" "}
        <select
          defaultValue="Thursday"
          onChange={(e) => setDay(e.target.value)}
        >
          <option>Thursday</option>
          <option>Saturday</option>
        </select>
      </h4>
      <br />
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Credits Remaining</th>
            <th>Breads per Week</th>
            <th>Assign Bread</th>
            <th>Order</th>
          </tr>
        </thead>
        <tbody>
          {users.map((u) => (
            <User key={u.id} {...u} menu={menu} onPickBread={handlePickBread} />
          ))}
        </tbody>
      </table>
    </>
  );
}
