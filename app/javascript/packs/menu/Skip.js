import React from "react";

export default function Skip() {
  return (
    <div className="col-6 mb-5">
      <div className="form-check">
        <label className="form-check-label">
          <input
            onChange={() => this.handleItemSelected("skip")}
            name="item"
            value="skip"
            className="form-check-input"
            type="radio"
          />
          I'd like to skip this week, please credit me for a future week (limit
          3 per 6 month period)
        </label>
      </div>
    </div>
  );
}
