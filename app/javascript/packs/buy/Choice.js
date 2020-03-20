import React, { useState } from 'react'
import _ from 'lodash'
import {formatMoney} from 'accounting'

export default function Choice({ frequency, credits, price, total, onChoose}) {
  const handleClick = ()=> {
    onChoose({ credits, price: total });
  };

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
