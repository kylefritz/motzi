import React, { useState } from "react";
import _ from "lodash";
import { formatMoney } from "accounting";

import BakersNote from "./BakersNote";
import Cart, { useCart, type AddToCartPayload } from "./Cart";
import Title from "./Title";
import Account from "./Account";
import Items from "./Items";
import PayItForward from "./PayItForward";
import Payment from "../buy/Payment";
import { applyTip } from "../buy/Tip";
import { cartPricing, isBelowMinimum, MAX_ABOVE_MINIMUM } from "../buy/pricing";
import PayWhatYouCan from "../buy/PayWhatYouCan";
import FeedbackForm from "./FeedbackForm";
import { useDeadlineContext, usePriceContext } from "./Contexts";
import type {
  CartItem,
  MarketplaceOrderRequest,
  Menu as MenuType,
  PaymentSubmission,
} from "../../types/api";

type AccountInfo = Pick<
  MarketplaceOrderRequest,
  "email" | "firstName" | "lastName" | "phone" | "mailingList"
>;

type MarketplaceProps = {
  menu: MenuType;
  onCreateOrder: (order: MarketplaceOrderRequest) => Promise<unknown>;
};

export default function Marketplace({ menu, onCreateOrder }: MarketplaceProps) {
  const { cart, addToCart, rmCartItem, total, marketplaceItems, payItForward } =
    useCart({
      items: menu.items,
    });
  const [submitting, setSubmitting] = useState(false);
  const [comments, setComments] = useState<string | null>(null);
  const [account, setAccount] = useState<AccountInfo>({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    mailingList: false,
  });
  const [price, setPrice] = useState<number | null>(total.price);
  const [tip, setTip] = useState<string | null>(null);
  const { allClosed } = useDeadlineContext();
  const { showCredits } = usePriceContext();

  const totalPrice = applyTip(price, tip);
  const canPay = () => {
    if (_.isEmpty(account.email)) {
      alert("Enter email!");
      return false;
    }
    if (!/\S+@\S+\.\S+/.test(account.email)) {
      alert("Invalid email");
      return false;
    }
    return true;
  };

  // Resolves with the server's response so a card that needs 3D Secure can
  // finish it and pay again (see buy/Card).
  const handlePay = (payment: PaymentSubmission) => {
    console.log("handlePay", { payment, price: totalPrice });
    setSubmitting(true);

    // send the stripe payment to rails to complete purchase
    const finalPrice = typeof totalPrice === "number" ? totalPrice : 0;
    return onCreateOrder({
      ...account,
      comments,
      cart,
      price: finalPrice,
      ...payment,
    }).finally(() => setSubmitting(false));
  };

  const handleAddToCart = (item: AddToCartPayload) => {
    const newCartPrice = addToCart(item);
    setPrice(newCartPrice);
  };

  const handleRemoveFromCart = (
    itemId: CartItem["itemId"],
    quantity: CartItem["quantity"],
    pickupDayId: CartItem["pickupDayId"]
  ) => {
    const newCartPrice = rmCartItem(itemId, quantity, pickupDayId);
    setPrice(newCartPrice);
  };

  if (!marketplaceItems.length) {
    console.warn("marketplace has no items", marketplaceItems);
    return null;
  }

  const { menuNote, enablePayWhatYouCan } = menu;
  const pricing = cartPricing({
    cart,
    items: menu.items,
    enablePayWhatYouCan,
  });
  const belowMinimum = isBelowMinimum(price, pricing.minimum);
  const menuClosed = allClosed(menu);
  const disabled = menuClosed || !onCreateOrder;
  const stripeApiKey = window.gon?.stripeApiKey;
  return (
    <>
      <Title menu={menu} />

      <BakersNote note={menuNote} />

      <h5>Menu</h5>
      <Items
        items={marketplaceItems}
        showPriceMarkers={enablePayWhatYouCan && !showCredits}
        onAddToCart={handleAddToCart}
        disabled={disabled}
      />
      {payItForward && (
        <PayItForward
          {...payItForward}
          onAddToCart={handleAddToCart}
          disabled={disabled}
        />
      )}

      <h5>Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            placeholder="Comments & special requests"
            defaultValue={comments ?? undefined}
            onChange={(e) => setComments(e.target.value)}
            className="form-control"
            disabled={disabled}
          />
        </div>
      </div>

      <Cart {...{ cart, menu, rmCartItem: handleRemoveFromCart }} />

      <div className="mt-3">
        <Account onChange={setAccount} disabled={disabled} />
      </div>
      {enablePayWhatYouCan ? (
        <PayWhatYouCan
          price={price}
          onPricedChanged={setPrice}
          disabled={disabled}
          tip={tip}
          onTip={setTip}
          pricing={pricing}
        />
      ) : (
        <br />
      )}
      <Payment
        price={_.isEmpty(cart) ? null : totalPrice}
        stripeApiKey={stripeApiKey}
        onPay={handlePay}
        canPay={canPay}
        maxPrice={pricing.minimum + MAX_ABOVE_MINIMUM}
        submitting={submitting}
        disabled={disabled}
        blockedText={
          !_.isEmpty(cart) && belowMinimum
            ? `Enter at least ${formatMoney(pricing.minimum)}`
            : null
        }
      />
      <FeedbackForm />
    </>
  );
}
