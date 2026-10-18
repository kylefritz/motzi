import React, { useState } from "react";
import { formatMoney } from "accounting";
import Tip from "./Tip";
import { FixedPriceTag, PayWhatYouCanTag } from "./PriceTags";
import {
  MAX_ABOVE_MINIMUM,
  isBelowMinimum,
  type CartPricing,
  type PricedLine,
} from "./pricing";

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
  // the breakdown and minimum only matter once a fixed-price item is in the cart
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
          {hasFixed &&
            " A few items have a fixed price because that money is owed to someone else, like a guest chef or a maker."}
        </small>
      </p>
      {fixed && <Breakdown pricing={fixed} />}
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
          className={`form-control ${belowMinimum ? "is-invalid" : ""}`}
          placeholder="Price"
          aria-label="Price"
          aria-describedby="you-pay you-pay-help"
          aria-invalid={belowMinimum}
          value={shownPrice === null ? 0 : shownPrice}
          onChange={handleInputChanged}
          onBlur={handleBlur}
          disabled={disabled}
        />
      </div>
      {belowMinimum ? (
        <p
          id="you-pay-help"
          role="alert"
          className="text-danger mb-3"
          data-testid="below-minimum"
        >
          <small>
            That's under {formatMoney(minimum)}, the total for the fixed-price
            items. Only the pay-what-you-can part can go lower.{" "}
            <button
              type="button"
              className="btn btn-link btn-sm p-0 align-baseline"
              onClick={handlePayMinimum}
            >
              Pay {formatMoney(minimum)}
            </button>
          </small>
        </p>
      ) : (
        fixed && (
          <p id="you-pay-help" className="mb-3">
            <small>
              {formatMoney(minimum)} covers the fixed-price items; the suggested
              total is {formatMoney(fixed.suggestedTotal)}. The rest is up to
              you.
            </small>
          </p>
        )
      )}
      <Tip {...{ price, tip, onTip }} />
    </>
  );
}

function Breakdown({ pricing }: { pricing: CartPricing }) {
  return (
    <div className="pwyc-breakdown mb-3" data-testid="price-breakdown">
      <BreakdownSection
        tag={<FixedPriceTag />}
        lines={pricing.fixedLines}
        totalLabel="Fixed total"
        total={pricing.fixedSubtotal}
      />
      {pricing.pwycLines.length > 0 && (
        <BreakdownSection
          tag={<PayWhatYouCanTag />}
          lines={pricing.pwycLines}
          totalLabel="Suggested"
          total={pricing.suggestedPwycSubtotal}
          muted
        />
      )}
    </div>
  );
}

function BreakdownSection({
  tag,
  lines,
  totalLabel,
  total,
  muted,
}: {
  tag: React.ReactNode;
  lines: PricedLine[];
  totalLabel: string;
  total: number;
  muted?: boolean;
}) {
  const amountClass = muted ? "text-muted" : "";
  return (
    <div className="pwyc-breakdown-section">
      <div className="mb-1">{tag}</div>
      {lines.map(({ itemId, name, quantity, subtotal }, index) => (
        <div key={`${itemId}:${index}`} className="pwyc-breakdown-line">
          <span>
            {quantity} × {name}
          </span>
          <span className={amountClass}>{formatMoney(subtotal)}</span>
        </div>
      ))}
      <div className="pwyc-breakdown-line pwyc-breakdown-total">
        <span>{totalLabel}</span>
        <span className={amountClass}>{formatMoney(total)}</span>
      </div>
    </div>
  );
}
