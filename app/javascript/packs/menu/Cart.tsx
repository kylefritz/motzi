import React from "react";
import _ from "lodash";
import { useState } from "react";
import moment from "moment";

import Price from "./Price";
import { getDeadlineContext, getPriceContext } from "./Contexts";
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
  skip?: boolean;
};

function Days({ menu, cart, rmCartItem, skip }: DaysProps) {
  const { isClosed } = getDeadlineContext();

  if (skip) {
    return (
      <div>
        <p>Skip this week</p>
      </div>
    );
  }

  const cartPickupDays = new Set(cart.map(({ pickupDayId }) => pickupDayId));
  const pickupDays = menu.pickupDays.filter(({ id: pickupDayId }) =>
    cartPickupDays.has(pickupDayId)
  );
  const [items, payItForward] = _.partition(
    cart,
    ({ itemId }) => itemId !== PAY_IT_FORWARD_ID
  );

  const sections = pickupDays.map(({ id, pickupAt, orderDeadlineAt }) => {
    const day = moment(pickupAt).format("dddd");
    const daysItems = items.filter(({ pickupDayId }) => pickupDayId === id);
    const canEdit = !isClosed(orderDeadlineAt);
    return (
      <div key={id}>
        <h6>{day}</h6>
        <DaysCart
          {...{
            menu,
            rmCartItem: canEdit && rmCartItem,
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
            rmCartItem: canEdit && rmCartItem,
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
  const { showCredits } = getPriceContext();
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
  const { cart, skip } = props;
  if (!cart.length && !skip) {
    return <p>No items</p>;
  }
  return (
    <>
      <Days {...props} />
      <Total {...props} />
    </>
  );
}

export default function CartWrapper(props: DaysProps & { cart: CartItemType[] }) {
  return (
    <>
      <h5>Your order</h5>
      <div className="ml-2">
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
  const addBy = (attribute) =>
    _.sum(
      cart.map(
        ({ itemId, quantity }) =>
          _.get(menuItemsById[itemId], attribute, 0) * quantity
      )
    );

  return { price: addBy("price"), credits: addBy("credits") };
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

type AddToCartPayload = {
  id: number;
  quantity: number;
  pickupDayId?: number;
  price?: number;
};

export function useCart({ order = null, items }: UseCartInput) {
  const [cart, setCart] = useState<CartItemType[]>(
    (_.get(order, "items", []) as MenuOrderItem[]) || []
  );

  const calcTotal = (cart: CartItemType[]) => cartTotal({ cart, items });

  const addToCart = ({ id: itemId, quantity, pickupDayId }: AddToCartPayload) => {
    console.log("addToCart", itemId, "x", quantity, "on", pickupDayId);
    const nextCart = [...cart, { itemId, quantity, pickupDayId }];
    setCart(nextCart);
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
    setCart(nextCart);
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
      throw "cant find pickupDay";
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
    addToCart,
    rmCartItem,
    setCart,
    total: calcTotal(cart),
    marketplaceItems,
    subscriberItems,
    payItForward,
  };
}
