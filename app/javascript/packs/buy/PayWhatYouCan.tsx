import React, { useState } from "react";
import Tip from "./Tip";

type PayWhatYouCanProps = {
  price: number | null;
  onPricedChanged: (price: number) => void;
  tip: string | null;
  onTip: (tip: string) => void;
  disabled?: boolean;
};

export default function PayWhatYouCan({
  price,
  onPricedChanged: handlePriceChanged,
  tip,
  onTip,
  disabled,
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

  return (
    <>
      <p>
        <small>
          These are suggested prices based on the our costs. We want everyone to
          have access to healthy food in this time of crisis and beyond,
          regardless of ability to pay. If you are out of work or otherwise in a
          challenging financial situation please pay what you can or nothing at
          all. If you have the means to pay more we would welcome your support
          in providing for the community and ensuring our continued stability as
          a small business.
        </small>
      </p>
      <div className="input-group mb-3">
        <div className="input-group-prepend">
          <span className="input-group-text" id="you-pay">
            You pay $
          </span>
        </div>
        <input
          type="number"
          min="0"
          max="250"
          className="form-control"
          placeholder="Price"
          aria-label="Price"
          aria-describedby="you-pay"
          value={tempPrice === null ? (price === null ? 0 : price) : tempPrice}
          onChange={handleInputChanged}
          onBlur={handleBlur}
          disabled={disabled}
        />
      </div>
      <Tip {...{ price, tip, onTip }} />
    </>
  );
}
