import React from "react";

// Small markers that say whether an item's price is a suggestion or owed in
// full (#412). Styles live in application.scss (.price-tag).

export function FixedPriceTag() {
  return <span className="price-tag price-tag-fixed">Fixed price</span>;
}

export function PayWhatYouCanTag() {
  return <span className="price-tag price-tag-pwyc">Pay what you can</span>;
}
