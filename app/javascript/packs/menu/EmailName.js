import React, { useState } from "react";

export default function EmailName({ onChange, disabled }) {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [optIn, setOptIn] = useState(false);

  const handle = (setterFunc) => {
    return (event) => {
      setterFunc(event.target.value);
      onChange({ email, firstName, lastName, optIn });
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
          id="optIn"
          checked={optIn}
          onChange={handle(setOptIn)}
        />
        <label className="form-check-label" htmlFor="optIn">
          Receive newsletter from Motzi?
        </label>
      </div>
    </>
  );
}
