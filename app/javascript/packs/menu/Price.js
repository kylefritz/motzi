import React from "react";
import accounting from "accounting";
import pluralize from "pluralize";
import _ from "lodash";

import { getPriceContext } from "./Contexts";

function Format({ price, credits = 1, stripeChargeAmount }) {
  const { showCredits } = getPriceContext();

  if (!_.isNil(stripeChargeAmount)) {
    return accounting.formatMoney(stripeChargeAmount);
  }

  if (showCredits) {
    return pluralize("credit", credits, true);
  }
  return accounting.formatMoney(price || 0);
}

export default function Price(props) {
  return (
    <div className="price my-2">
      <Format {...props} />
    </div>
  );
}
