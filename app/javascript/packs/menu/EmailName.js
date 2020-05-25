import React, { useState } from "react";

export default function EmailName({ onChange }) {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");

  const handle = (setterFunc) => {
    return (event) => {
      setterFunc(event.target.value);
      onChange({ email, firstName, lastName });
    };
  };

  return (
    <>
      <h5>Your info</h5>
      <div className="form-group">
        <label>
          Email
          <input
            required
            type="email"
            value={email}
            onChange={handle(setEmail)}
            className="form-control"
          />
        </label>
      </div>
      <div className="form-group">
        <label>
          First Name
          <input
            required
            value={firstName}
            onChange={handle(setFirstName)}
            className="form-control"
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
          />
        </label>
      </div>
    </>
  );
}
