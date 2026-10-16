import React from "react";
import { formatMoney } from "accounting";
import type { CreditBundle } from "../../types/api";

type ChoiceTextProps = Pick<CreditBundle, "description" | "credits" | "price">;

function ChoiceText({ description, credits, price }: ChoiceTextProps) {
  if (description) {
    return (
      <>
        {description}
        <br />
        <small>
          {`${credits} credits at ${formatMoney(price / credits)} ea`}
        </small>
      </>
    );
  }

  return (
    <>
      {`${credits} credits`}
      <br />
      <small>{`${formatMoney(price / credits)} ea`}</small>
    </>
  );
}

type ChoiceProps = Pick<
  CreditBundle,
  "description" | "credits" | "price" | "breadsPerWeek"
> & {
  onChoose: (
    choice: Pick<CreditBundle, "credits" | "price" | "breadsPerWeek">
  ) => void;
};

export default function Choice({
  description,
  credits,
  price,
  onChoose,
  breadsPerWeek,
}: ChoiceProps) {
  const handleClick = () => {
    onChoose({ credits, price, breadsPerWeek });
  };
  return (
    <button
      type="button"
      className="btn btn-sm btn-light mb-3 mr-2"
      onClick={handleClick}
    >
      <ChoiceText {...{ description, credits, price }} />
      <br />
      {formatMoney(price)}
    </button>
  );
}
