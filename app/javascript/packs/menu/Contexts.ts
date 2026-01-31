import React, { useContext } from "react";
import moment from "moment";
import _ from "lodash";
import type { MenuPickupDay, CreditBundle } from "../../types/api";

function pastDeadline(deadline: string) {
  const now = moment();
  return now > moment(deadline);
}

type DayContextValue = {
  orderingDeadlineText?: string;
  ignoreDeadline?: boolean | string | null;
};

type SettingsContextValue = {
  enablePayWhatYouCan?: boolean;
  bundles?: CreditBundle[];
  onRefresh?: () => void;
  showCredits?: boolean;
};

const DayContext = React.createContext<DayContextValue | null>(null);
const SettingsContext = React.createContext<SettingsContextValue | null>(null);

export { DayContext, SettingsContext };

export function getSettingsContext(): SettingsContextValue {
  const ctx = useContext(SettingsContext);
  if (_.isNil(ctx)) {
    console.warn("SettingsContext is nil", ctx);
  }
  return ctx || ({} as SettingsContextValue);
}

// like getSettingsContext but just for prices & doesn't warn
export function getPriceContext() {
  const ctx = useContext(SettingsContext);
  const { showCredits = false } = ctx || {};
  return { showCredits };
}

export function getDeadlineContext() {
  const ctx = useContext(DayContext) || ({} as DayContextValue);

  const isClosed = (orderDeadlineAt: string) => {
    if (ctx.ignoreDeadline) {
      return false;
    }

    return pastDeadline(orderDeadlineAt);
  };

  const allClosed = ({
    pickupDays,
  }: {
    pickupDays?: MenuPickupDay[];
  }) => {
    if (ctx.ignoreDeadline) {
      return false;
    }
    if (pickupDays === undefined) {
      console.warn("called with pickupDays = undefined");
      return false;
    }

    const lastPickupDay = _.last(pickupDays);
    if (!lastPickupDay || !lastPickupDay.orderDeadlineAt) {
      return false;
    }

    return isClosed(lastPickupDay.orderDeadlineAt);
  };

  return { ...ctx, isClosed, allClosed };
}
