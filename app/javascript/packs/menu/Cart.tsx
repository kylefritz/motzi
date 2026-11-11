import React from "react";
import _ from "lodash";
import { useState } from "react";
import { weekday } from "../../lib/dates";

import Price from "./Price";
import { useDeadlineContext, usePriceContext } from "./Contexts";
import type {
  CartItem as CartItemType,
  Menu as MenuType,
  MenuItem,
  MenuOrder,
  MenuOrderItem,
} from "../../types/api";

const PAY_IT_FORWARD_ID = -1;

type CartItemProps = {
  itemId: number;
  quantity: number;
  pickupDayId?: number;
  name: string;
  rmCartItem?: (itemId: number, quantity: number, pickupDayId?: number) => void;
};

function CartItem({
  itemId,
  quantity,
  pickupDayId,
  name,
  rmCartItem,
}: CartItemProps) {
  return (
    <div className="row mb-3">
      <div className="col-1" />
      <div className="col">
        {quantity > 1 && <strong className="mr-2">{quantity}x</strong>}
        {name}
      </div>
      {rmCartItem && (
        <div className="col">
          <button
            type="button"
            className="close"
            aria-label="Close"
            onClick={() => rmCartItem(itemId, quantity, pickupDayId)}
          >
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
      )}
    </div>
  );
}

function DaysCart({
  menu: { items },
  cart,
  rmCartItem,
}: {
  menu: Pick<MenuType, "items">;
  cart: CartItemType[];
  rmCartItem?: (itemId: number, quantity: number, pickupDayId?: number) => void;
}) {
  const menuItemsById = _.keyBy(items, ({ id }) => id);

  return (
    <>
      {cart.map(({ itemId, quantity, pickupDayId }, index) => {
        const item = menuItemsById[itemId];
        const name = (item && item.name) || `Item ${itemId}`;
        return (
          <CartItem
            key={`${index}:${itemId}:${quantity}:${pickupDayId}`}
            {...{ itemId, quantity, pickupDayId, name, rmCartItem }}
          />
        );
      })}
    </>
  );
}

type DaysProps = {
  menu: MenuType;
  cart: CartItemType[];
  rmCartItem?: (itemId: number, quantity: number, pickupDayId?: number) => void;
};

function Days({ menu, cart, rmCartItem }: DaysProps) {
  const { isClosed } = useDeadlineContext();

  const cartPickupDays = new Set(cart.map(({ pickupDayId }) => pickupDayId));
  const pickupDays = menu.pickupDays.filter(({ id: pickupDayId }) =>
    cartPickupDays.has(pickupDayId)
  );
  const [items, payItForward] = _.partition(
    cart,
    ({ itemId }) => itemId !== PAY_IT_FORWARD_ID
  );

  const sections = pickupDays.map(({ id, pickupAt, orderDeadlineAt }) => {
    const day = weekday(pickupAt);
    const daysItems = items.filter(({ pickupDayId }) => pickupDayId === id);
    const canEdit = !isClosed(orderDeadlineAt);
    return (
      <div key={id}>
        <h6>{day}</h6>
        <DaysCart
          {...{
            menu,
            rmCartItem: canEdit ? rmCartItem : undefined,
            cart: daysItems,
          }}
        />
      </div>
    );
  });

  if (payItForward.length) {
    const lastPickupDay = menu.pickupDays[menu.pickupDays.length - 1];
    const canEdit = !isClosed(lastPickupDay.orderDeadlineAt);
    sections.push(
      <div key="pay-it-forward">
        <h6>Pay It Forward</h6>
        <DaysCart
          {...{
            menu,
            rmCartItem: canEdit ? rmCartItem : undefined,
            cart: payItForward,
          }}
        />
      </div>
    );
  }

  return sections;
}

function Total({
  cart,
  menu: { items },
  stripeChargeAmount,
}: {
  cart: CartItemType[];
  menu: Pick<MenuType, "items">;
  stripeChargeAmount?: number | null;
}) {
  const { price, credits } = cartTotal({ cart, items });
  const { showCredits } = usePriceContext();
  const showPrices = !showCredits;
  return (
    <div>
      <h6>
        Total
        {showPrices && <small className="ml-3">includes taxes & fees</small>}
      </h6>
      <div className="row">
        <div className="col-1" />
        <div className="col">
          <Price {...{ price, credits, stripeChargeAmount }} />
        </div>
      </div>
    </div>
  );
}

function Cart(props: DaysProps & { cart: CartItemType[] }) {
  const { cart } = props;
  if (!cart.length) {
    return <p>No items</p>;
  }
  return (
    <>
      <Days {...props} />
      <Total {...props} />
    </>
  );
}

// Lines dropped from an order being edited (see useCart's removedItems).
function RemovedNote({
  menu: { items },
  removedItems,
}: {
  menu: Pick<MenuType, "items">;
  removedItems: CartItemType[];
}) {
  const menuItemsById = _.keyBy(items, ({ id }) => id);
  const names = _.uniq(
    removedItems.map(
      ({ itemId }) => menuItemsById[itemId]?.name || `Item ${itemId}`
    )
  );
  if (!names.length) {
    return null;
  }
  const one = names.length === 1;
  return (
    <div
      role="status"
      className="alert alert-warning py-2 px-3"
      data-testid="removed-from-order"
    >
      <small>
        {names.join(", ")} {one ? "isn't" : "aren't"} available for that pickup
        day anymore, so we took {one ? "it" : "them"} out of your order.
      </small>
    </div>
  );
}

export default function CartWrapper({
  removedItems = [],
  ...props
}: DaysProps & { cart: CartItemType[]; removedItems?: CartItemType[] }) {
  return (
    <>
      <h5>Your order</h5>
      <div className="ml-2">
        <RemovedNote menu={props.menu} removedItems={removedItems} />
        <Cart {...props} />
      </div>
    </>
  );
}

type CartTotal = { price: number | null; credits: number };

function cartTotal({
  cart,
  items,
}: {
  cart: CartItemType[];
  items: MenuItem[];
}): CartTotal {
  if (cart.length === 0) {
    return { price: null, credits: 0 };
  }
  const menuItemsById = _.keyBy(items, ({ id }) => id);
  const addBy = (attribute: "price" | "credits") =>
    _.sum(
      cart.map(
        ({ itemId, quantity }) =>
          _.get(menuItemsById[itemId], attribute, 0) * quantity
      )
    );

  // whole cents: 3 × $0.60 is 1.7999999999999998 as a float
  const price = Math.round(addBy("price") * 100) / 100;
  return { price, credits: addBy("credits") };
}

export function orderCredits({
  order,
  items,
}: {
  order: MenuOrder | null;
  items: MenuItem[];
}) {
  const orderItems = _.get(order, "items", []) as MenuOrderItem[];
  return cartTotal({ cart: orderItems, items }).credits;
}

type UseCartInput = {
  order?: MenuOrder | null;
  items: MenuItem[];
};

export type AddToCartPayload = {
  id: number;
  quantity: number;
  pickupDayId?: number;
  price?: number;
};

export function useCart({ order = null, items }: UseCartInput) {
  const [savedCart, setCart] = useState<CartItemType[]>(
    (_.get(order, "items", []) as MenuOrderItem[]) || []
  );

  // A line can outlive its pickup day: the bakery may take a day off an item
  // after members have ordered it. Those lines can't be edited or re-saved,
  // so they leave the cart and are handed back as removedItems for a note.
  const itemsById = _.keyBy(items, ({ id }) => id);
  const [cart, removedItems] = _.partition(
    savedCart,
    ({ itemId, pickupDayId }) => {
      const item = itemsById[itemId];
      if (itemId === PAY_IT_FORWARD_ID || !item) {
        return true;
      }
      return item.pickupDays.some(({ id }) => id === pickupDayId);
    }
  );

  const calcTotal = (cart: CartItemType[]) => cartTotal({ cart, items });

  const addToCart = ({
    id: itemId,
    quantity,
    pickupDayId,
  }: AddToCartPayload) => {
    console.log("addToCart", itemId, "x", quantity, "on", pickupDayId);
    const nextCart = [...cart, { itemId, quantity, pickupDayId }];
    setCart([...nextCart, ...removedItems]);
    return calcTotal(nextCart).price;
  };

  const rmCartItem = (
    itemId: number,
    quantity: number,
    pickupDayId?: number
  ) => {
    const index = _.findIndex(
      cart,
      (ci) =>
        ci.itemId === itemId &&
        ci.quantity === quantity &&
        ci.pickupDayId === pickupDayId
    );
    console.log("rmCartItem", { itemId, quantity, pickupDayId }, "@", index);
    const nextCart = [...cart];
    nextCart.splice(index, 1);
    setCart([...nextCart, ...removedItems]);
    return calcTotal(nextCart).price;
  };
  // update pickupDay.remaining on items
  const itemLookup = _.keyBy(_.cloneDeep(items), ({ id }) => id);
  const payItForward = itemLookup[PAY_IT_FORWARD_ID];
  cart.forEach(({ itemId, quantity, pickupDayId }) => {
    if (itemId === PAY_IT_FORWARD_ID) {
      return;
    }
    const item = itemLookup[itemId];
    if (!item) {
      console.warn(`item in cart ${itemId} but not on menu`);
      return;
    }
    const pickupDay = item.pickupDays.find(({ id }) => id === pickupDayId);
    if (pickupDay === undefined) {
      return; // already moved to removedItems above
    }
    pickupDay.remaining -= quantity;
  });

  // maintain original order
  const nextItems = items
    .filter(({ id }) => id !== PAY_IT_FORWARD_ID)
    .map(({ id }) => itemLookup[id]);

  const marketplaceItems = nextItems.filter(({ marketplace }) => marketplace);
  const subscriberItems = nextItems.filter(({ subscriber }) => subscriber);

  return {
    cart,
    removedItems,
    addToCart,
    rmCartItem,
    setCart,
    total: calcTotal(cart),
    marketplaceItems,
    subscriberItems,
    payItForward,
  };
}
