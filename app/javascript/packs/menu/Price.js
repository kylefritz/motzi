import React, { useContext } from "react";
import accounting from "accounting";
import pluralize from "pluralize";

import { UserContext } from "./Contexts";

export default function Price({ price, credits = 1, stripeChargeAmount }) {
  const user = useContext(UserContext);

  if (!_.isNil(stripeChargeAmount)) {
    return <div>{accounting.formatMoney(stripeChargeAmount)}</div>;
  }

  if (user) {
    return (
      <div>
        {pluralize("credit", credits, true)}{" "}
        <span className="text-muted">or {accounting.formatMoney(price)} </span>
      </div>
    );
  }

  return (
    <div>
      {accounting.formatMoney(price)}{" "}
      <span className="text-success">
        or {pluralize("credit", credits, true)}
      </span>
    </div>
  );
}
