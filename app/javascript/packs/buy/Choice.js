import React, { useState } from 'react'
import _ from 'lodash'

export default function Choice({ name, value: maybeValue, price, onChoose }) {
  const value = maybeValue || _.toLower(name)
  return (
    <div className="col-6 mb-2">
      <div className="form-check">
        <label className="form-check-label">
          <input
            className="form-check-input"
            type="radio"
            name="checkout"
            value={value}
            onChange={() => onChoose(value)}
          />
          {name} <br />
          {price && <small>${price}</small>}
        </label>
      </div>
    </div>
  );
}
