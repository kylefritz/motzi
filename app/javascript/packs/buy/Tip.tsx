import React, { useState } from "react";

function TipBtn({ text, onClick, selected }) {
  const cls = selected ? "btn-primary" : "btn-outline-primary";
  return (
    <button type="button" onClick={onClick} className={`btn ml-2 ${cls}`}>
      {text}
    </button>
  );
}

const style = {
  display: "flex",
  placeContent: "flex-end",
  alignItems: "center",
};

export default function Tip({ price, tip, onTip }) {
  const quantities =
    price && price < 10 ? ["$1", "$3", "$5"] : ["5%", "10%", "15%"];
  return (
    <div style={style} className="mb-3">
      Add a tip:
      {quantities.map((val) => (
        <TipBtn
          key={val}
          text={val}
          selected={tip === val}
          onClick={() => {
            onTip(val);
          }}
        />
      ))}
    </div>
  );
}

export function applyTip(price, tip) {
  if (!tip) {
    return price;
  }
  if (tip[0] === "$") {
    return price + parseFloat(tip.slice(1));
  }
  if (tip.slice(tip.length - 1) === "%") {
    const fraction = 1.0 + parseFloat(tip.slice(0, tip.length - 1)) / 100.0;
    return parseFloat((price * fraction).toFixed(2));
  }
}
