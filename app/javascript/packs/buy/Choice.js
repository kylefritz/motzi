import React, { useState } from 'react'
import _ from 'lodash'
import {formatMoney} from 'accounting'

export default function Choice({ credits, price, total, onChoose, breadsPerWeek}) {
  const handleClick = ()=> {
    onChoose({ credits, price: total, breadsPerWeek });
  };
  const frequency = breadsPerWeek === 1.0 ? "Weekly" : "Bi-Weekly";
  return (
      <button type="button" className="btn btn-sm btn-light mb-3 mr-2" onClick={handleClick}>
        {frequency}<br/>
        <small>
          {`${credits} credits at ${formatMoney(price)} ea`}<br/>
        </small>
        {formatMoney(total)}
      </button>
  );
}
