import React, { useState } from "react";

export default function EmailName({ onChange, disabled }) {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [sendWeeklyEmail, setSendWeeklyEmail] = useState(false);

  const handle = (setterFunc) => {
    return (event) => {
      setterFunc(event.target.value);
      onChange({ email, firstName, lastName, sendWeeklyEmail });
    };
  };

  return (
    <>
      <h5>Your info</h5>
      <div className="form-group">
        <label>
          First Name
          <input
            required
            value={firstName}
            onChange={handle(setFirstName)}
            className="form-control"
            disabled={disabled}
          />
        </label>
      </div>
      <div className="form-group">
        <label>
          Last Name
          <input
            required
            value={lastName}
            onChange={handle(setLastName)}
            className="form-control"
            disabled={disabled}
          />
        </label>
      </div>
      <div className="form-group">
        <label>
          Email
          <input
            required
            type="email"
            value={email}
            onChange={handle(setEmail)}
            className="form-control"
            disabled={disabled}
          />
        </label>
      </div>
      <div className="form-group form-check">
        <input
          type="checkbox"
          className="form-check-input"
          id="sendWeeklyEmail"
          checked={sendWeeklyEmail}
          onChange={handle(setSendWeeklyEmail)}
        />
        <label className="form-check-label" htmlFor="sendWeeklyEmail">
          Receive an email with week's menu?
        </label>
      </div>
    </>
  );
}
