import React, { useState } from "react";
import { formatMoney } from "accounting";
import Tip from "./Tip";
import { MAX_ABOVE_MINIMUM, isBelowMinimum, type CartPricing } from "./pricing";

type PayWhatYouCanProps = {
  price: number | null;
  onPricedChanged: (price: number) => void;
  tip: string | null;
  onTip: (tip: string) => void;
  disabled?: boolean;
  // an order's cart priced by line; credit purchases have no fixed lines
  pricing?: CartPricing;
};

export default function PayWhatYouCan({
  price,
  onPricedChanged: handlePriceChanged,
  tip,
  onTip,
  disabled,
  pricing,
}: PayWhatYouCanProps) {
  const [tempPrice, setTempPrice] = useState<number | null>(null);

  const handleInputChanged = ({
    target,
  }: React.ChangeEvent<HTMLInputElement>) => {
    const nextPrice = parseFloat(target.value);
    setTempPrice(nextPrice);

    if (nextPrice === 0 || price === 0) {
      handlePriceChanged(nextPrice);
    }
  };

  const handleBlur = ({ target }: React.FocusEvent<HTMLInputElement>) => {
    handlePriceChanged(parseFloat(target.value));
    setTempPrice(null);
  };

  const handlePayMinimum = () => {
    if (pricing) {
      handlePriceChanged(pricing.minimum);
      setTempPrice(null);
    }
  };

  const minimum = pricing?.minimum ?? 0;
  // the minimum only matters once a fixed-price item is in the cart
  const fixed = pricing && pricing.fixedLines.length > 0 ? pricing : null;
  const hasFixed = fixed !== null;
  const shownPrice = tempPrice === null ? price : tempPrice;
  const belowMinimum = hasFixed && isBelowMinimum(shownPrice, minimum);

  return (
    <>
      <p>
        <small>
          Our prices are suggestions. We want everyone to be able to eat good
          bread, so if money's tight, pay what you can. If you're able to pay a
          little more, it helps us keep the oven on for the whole neighborhood.
        </small>
      </p>
      <div
        className={`input-group ${belowMinimum ? "mb-2" : "mb-3"}`}
        data-testid="you-pay"
      >
        <div className="input-group-prepend">
          <span className="input-group-text" id="you-pay">
            You pay $
          </span>
        </div>
        <input
          type="number"
          min={minimum}
          max={minimum + MAX_ABOVE_MINIMUM}
          className="form-control"
          placeholder="Price"
          aria-label="Price"
          aria-describedby={belowMinimum ? "you-pay you-pay-help" : "you-pay"}
          aria-invalid={belowMinimum}
          value={shownPrice === null ? 0 : shownPrice}
          onChange={handleInputChanged}
          onBlur={handleBlur}
          disabled={disabled}
        />
      </div>
      {belowMinimum && (
        <div
          id="you-pay-help"
          role="status"
          className="alert alert-warning py-2 px-3 mb-3"
          data-testid="below-minimum"
        >
          <small>
            A few things in your cart have a set price because that money goes
            to someone else, like a guest chef or a maker, so the total needs to
            be at least {formatMoney(minimum)}.{" "}
            <button
              type="button"
              className="btn btn-link btn-sm p-0 align-baseline"
              onClick={handlePayMinimum}
            >
              Change to {formatMoney(minimum)}
            </button>
          </small>
        </div>
      )}
      <Tip {...{ price, tip, onTip }} />
    </>
  );
}
