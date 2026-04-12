import React, { useState } from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import BuyCredits from "../buy/App";
import Cart, { useCart, orderCredits } from "./Cart";
import Title from "./Title";
import Items from "./Items";
import PayItForward from "./PayItForward";
import SkipNote from "./SkipNote";
import FeedbackForm from "./FeedbackForm";
import Subscription from "./Subscription";
import { getDeadlineContext } from "./Contexts";
import type {
  Menu as MenuType,
  MenuOrder,
  MenuOrderRequest,
  MenuUser,
} from "../../types/api";

type MenuProps = {
  menu: MenuType;
  order: MenuOrder | null;
  user: MenuUser;
  onCreateOrder: (order: MenuOrderRequest) => Promise<unknown>;
  isHoliday?: boolean;
  onShowEmailSettings?: () => void;
};

export default function Menu({ menu, order, user, onCreateOrder, isHoliday, onShowEmailSettings }: MenuProps) {
  const {
    cart,
    addToCart,
    rmCartItem,
    setCart,
    total,
    subscriberItems,
    payItForward,
  } = useCart({
    order,
    items: menu.items,
  });
  const [comments, setComments] = useState<string | null>(
    _.get(order, "comments", null)
  );

  const handleCreateOrder = () => {
    if (_.isEmpty(cart)) {
      alert("Make a selection!");
      return;
    }

    onCreateOrder({
      comments,
      cart,
      uid: user.hashid,
    });
  };

  // if editing an order, "give back" credits from the order
  const userCredits = user.credits + orderCredits({ order, items: menu.items });
  if (!isHoliday && userCredits < 1) {
    // Must buy credits!
    return (
      <>
        <Subscription user={user} showBuyMoreButton={false} onShowEmailSettings={onShowEmailSettings} />
        <p className="my-2 text-center">
          Buy credits then trade them for yummy things!
        </p>
        <BuyCredits user={user} />

      <h5 className="mt-5">Preview of current menu</h5>
      <Items
        items={subscriberItems}
        disabled={true}
      />
      </>
    );
  }

  const { subscriberNote, isCurrent } = menu;
  const menuClosed = getDeadlineContext().allClosed(menu);
  const insufficientCredits = !isHoliday && total.credits > userCredits;
  return (
    <>
      <Subscription user={user} showBuyMoreButton={!isHoliday} onShowEmailSettings={onShowEmailSettings} />

      {/* if low, show nag to buy credits*/}
      {!isHoliday && (userCredits < 4 || insufficientCredits) && <BuyCredits user={user} />}

      <Title menu={menu} />

      <BakersNote note={subscriberNote} />

      <h5>Menu</h5>
      <Items items={subscriberItems} onAddToCart={addToCart} />

      {!isHoliday && <SkipNote />}

      {payItForward && (
        <PayItForward
          {...payItForward}
          onAddToCart={addToCart}
          disabled={menuClosed}
        />
      )}

      <h5>Feedback, Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            style={{ minHeight: 120 }}
            placeholder="We'd love to hear your feedback on previous order or any comments/special requests you may have"
            defaultValue={comments}
            onChange={(e) => setComments(e.target.value)}
            className="form-control"
            disabled={menuClosed}
          />
        </div>
      </div>
      <Cart {...{ cart, menu, rmCartItem }} />
      <div className="row mt-2 mb-3">
        <div className="col">
          <SubmitButton
            onClick={handleCreateOrder}
            status={{
              isCurrent,
              menuClosed,
              insufficientCredits,
              isEditing: !!order,
            }}
          />
        </div>
      </div>
      <FeedbackForm />
    </>
  );
}

function buttonText({ isCurrent, menuClosed, insufficientCredits, isEditing }) {
  const no = (text, title) => ({ disabled: true, title, text });
  if (!isCurrent) {
    return no(
      "Old menu",
      "This is not the current menu; you cannot submit an order."
    );
  }
  if (menuClosed) {
    return no("Ordering closed", "Ordering for this menu is closed");
  }
  if (insufficientCredits) {
    return no(
      "Buy more credits :)",
      "You don't have enough credits to cover your cart."
    );
  }
  const text = isEditing ? "Update Order" : "Submit Order";
  return { disabled: false, title: null, text };
}

function SubmitButton({ onClick, status }) {
  const { disabled, title, text } = buttonText(status);
  return (
    <button
      {...{ onClick, disabled, title }}
      className="btn btn-primary btn-lg btn-block"
      type="submit"
    >
      {text}
    </button>
  );
}
