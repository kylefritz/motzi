import React, { useState } from "react";

export default function EmailName({ onChange, disabled }) {
  const [account, setAccount] = useState({
    firstName: "",
    lastName: "",
    email: "",
    optIn: false,
  });

  const handle = (fieldName) => {
    return (event) => {
      const fieldValue = event.target.value;
      const nextAccount = { ...account, [fieldName]: fieldValue };
      setAccount(nextAccount);
      onChange(nextAccount);
    };
  };
  const { firstName, lastName, email, optIn } = account;
  return (
    <>
      <h5>Your info</h5>
      <div className="form-group">
        <label>
          First Name
          <input
            required
            name="firstName"
            value={firstName}
            onChange={handle("firstName")}
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
            name="lastName"
            value={lastName}
            onChange={handle("lastName")}
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
            name="email"
            value={email}
            onChange={handle("email")}
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
          name="optIn"
          checked={optIn}
          onChange={handle("optIn")}
        />
        <label className="form-check-label" htmlFor="optIn">
          Receive newsletter?
        </label>
      </div>
    </>
  );
}
