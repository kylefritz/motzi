import React from "react";

type TipBtnProps = {
  text: string;
  onClick: () => void;
  selected: boolean;
};

function TipBtn({ text, onClick, selected }: TipBtnProps) {
  const cls = selected ? "btn-primary" : "btn-outline-primary";
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={selected}
      className={`btn ml-2 ${cls}`}
    >
      {text}
    </button>
  );
}

const style: React.CSSProperties = {
  display: "flex",
  flexWrap: "wrap",
  placeContent: "flex-end",
  alignItems: "center",
  rowGap: "0.5rem",
};

type TipProps = {
  price: number | null;
  tip: string | null | undefined;
  onTip: (tip: string | null) => void;
};

export default function Tip({ price, tip, onTip }: TipProps) {
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
      <TipBtn text="No tip" selected={!tip} onClick={() => onTip(null)} />
    </div>
  );
}

export function applyTip(
  price: number | null,
  tip: string | null
): number | null {
  if (!tip || price === null) {
    return price;
  }
  if (tip[0] === "$") {
    return parseFloat((price + parseFloat(tip.slice(1))).toFixed(2));
  }
  if (tip.slice(tip.length - 1) === "%") {
    const fraction = 1.0 + parseFloat(tip.slice(0, tip.length - 1)) / 100.0;
    return parseFloat((price * fraction).toFixed(2));
  }
  return price;
}
