import React, { useState } from "react";
import _ from "lodash";
import { formatMoney } from "accounting";

export default function Choice({
  name,
  description,
  credits,
  price,
  onChoose,
  breadsPerWeek,
}) {
  const handleClick = () => {
    onChoose({ credits, price, breadsPerWeek });
  };
  return (
    <button
      type="button"
      className="btn btn-sm btn-light mb-3 mr-2"
      onClick={handleClick}
    >
      {name}
      <br />
      {description}
      <small>
        {`${credits} credits at ${formatMoney(price / credits)} ea`}
        <br />
      </small>
      {formatMoney(price)}
    </button>
  );
}
