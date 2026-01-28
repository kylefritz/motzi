import React, { useState } from "react";
import _ from "lodash";
import { formatMoney } from "accounting";

function ChoiceText({ description, credits, price }) {
  if (description) {
    return (
      <>
        {description}
        <br />
        <small>
          {`${credits} credits at ${formatMoney(price / credits)} ea`}
        </small>
      </>
    );
  }

  return (
    <>
      {`${credits} credits`}
      <br />
      <small>{`${formatMoney(price / credits)} ea`}</small>
    </>
  );
}

export default function Choice({
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
      <ChoiceText {...{ description, credits, price }} />
      <br />
      {formatMoney(price)}
    </button>
  );
}
