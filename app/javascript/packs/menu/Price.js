import React, { useContext } from "react";
import accounting from "accounting";
import pluralize from "pluralize";
import _ from "lodash";

import { UserContext } from "./Contexts";

function Format({ price, credits = 1, stripeChargeAmount }) {
  const user = useContext(UserContext);

  if (!_.isNil(stripeChargeAmount)) {
    return accounting.formatMoney(stripeChargeAmount);
  }

  if (user) {
    return pluralize("credit", credits, true);
  }
  return accounting.formatMoney(price || 0);
}

export default function Price(props) {
  return (
    <div>
      <Format {...props} />
    </div>
  );
}
