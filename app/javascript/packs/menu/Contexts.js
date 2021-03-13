import React, { useContext } from "react";
import moment from "moment";
import _ from "lodash";

function pastDeadline(deadline) {
  const now = moment();
  return now > moment(deadline);
}

const DayContext = React.createContext();
const SettingsContext = React.createContext();

export { DayContext, SettingsContext };

export function getSettingsContext() {
  const ctx = useContext(SettingsContext);
  if (_.isNil(ctx)) {
    console.warn("SettingsContext is nil", ctx);
  }
  return ctx || {};
}

// like getSettingsContext but just for prices & doesn't warn
export function getPriceContext() {
  const ctx = useContext(SettingsContext);
  const { showCredits = false } = ctx || {};
  return { showCredits };
}

export function getDeadlineContext() {
  const ctx = useContext(DayContext) || {};

  const isClosed = (orderDeadlineAt) => {
    if (ctx.ignoreDeadline) {
      return false;
    }

    return pastDeadline(orderDeadlineAt);
  };

  const allClosed = ({ pickupDays }) => {
    if (ctx.ignoreDeadline) {
      return false;
    }

    const lastPickupDay = pickupDays[pickupDays.length - 1];
    return isClosed(lastPickupDay.orderDeadlineAt);
  };

  return { ...ctx, isClosed, allClosed };
}
