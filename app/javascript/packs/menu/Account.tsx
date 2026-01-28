import React, { useState } from "react";
import type { MarketplaceOrderRequest } from "../../types/api";

type AccountInfo = Pick<
  MarketplaceOrderRequest,
  "firstName" | "lastName" | "email" | "phone" | "optIn"
>;

type AccountProps = {
  onChange: (next: AccountInfo) => void;
  disabled?: boolean;
};

export default function Account({ onChange, disabled }: AccountProps) {
  const [account, setAccount] = useState<AccountInfo>({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    optIn: false,
  });

  const handle = (fieldName: keyof AccountInfo) => {
    return (event: React.ChangeEvent<HTMLInputElement>) => {
      const fieldValue =
        fieldName === "optIn" ? event.target.checked : event.target.value;
      const nextAccount = { ...account, [fieldName]: fieldValue };
      setAccount(nextAccount);
      onChange(nextAccount);
    };
  };
  const { firstName, lastName, email, phone, optIn } = account;
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
      <div className="form-group">
        <label>
          Phone
          <input
            required
            type="tel"
            name="phone"
            value={phone}
            onChange={handle("phone")}
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
          disabled={disabled}
        />
        <label className="form-check-label" htmlFor="optIn">
          Receive newsletter?
        </label>
      </div>
    </>
  );
}
