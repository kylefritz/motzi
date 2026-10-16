import _ from "lodash";
import type { CartItem, MenuItem } from "../../types/api";

// Mirrors OrderPricing (app/models/order_pricing.rb), which has the final say.
// Pay-what-you-can lines carry a suggested price the customer may go under;
// fixed lines are owed in full, so their total is the order's minimum.

// Upper bound on the amount beyond the minimum (OrderPricing::MAX_ABOVE_MINIMUM)
export const MAX_ABOVE_MINIMUM = 250;

export type PricedLine = {
  itemId: number;
  name: string;
  quantity: number;
  subtotal: number;
};

export type CartPricing = {
  fixedLines: PricedLine[];
  pwycLines: PricedLine[];
  fixedSubtotal: number;
  suggestedPwycSubtotal: number;
  suggestedTotal: number;
  minimum: number;
};

export function isPayWhatYouCan(
  item: Pick<MenuItem, "payWhatYouCan"> | undefined,
  enablePayWhatYouCan: boolean
) {
  return enablePayWhatYouCan && (item?.payWhatYouCan ?? true);
}

const roundCents = (amount: number) => Math.round(amount * 100) / 100;

export function cartPricing({
  cart,
  items,
  enablePayWhatYouCan,
}: {
  cart: CartItem[];
  items: MenuItem[];
  enablePayWhatYouCan: boolean;
}): CartPricing {
  const itemsById = _.keyBy(items, ({ id }) => id);
  const lines = cart.flatMap(({ itemId, quantity }) => {
    const item = itemsById[itemId];
    if (!item) {
      return [];
    }
    const line: PricedLine = {
      itemId,
      name: item.name,
      quantity,
      subtotal: roundCents(item.price * quantity),
    };
    return [{ line, pwyc: isPayWhatYouCan(item, enablePayWhatYouCan) }];
  });

  const fixedLines = lines.filter(({ pwyc }) => !pwyc).map(({ line }) => line);
  const pwycLines = lines.filter(({ pwyc }) => pwyc).map(({ line }) => line);
  const sum = (ls: PricedLine[]) => roundCents(_.sumBy(ls, "subtotal"));
  const fixedSubtotal = sum(fixedLines);
  const suggestedPwycSubtotal = sum(pwycLines);

  return {
    fixedLines,
    pwycLines,
    fixedSubtotal,
    suggestedPwycSubtotal,
    suggestedTotal: roundCents(fixedSubtotal + suggestedPwycSubtotal),
    minimum: fixedSubtotal,
  };
}

export function isBelowMinimum(price: number | null, minimum: number) {
  if (minimum <= 0) {
    return false;
  }
  return price === null || Number.isNaN(price) || price < minimum;
}
