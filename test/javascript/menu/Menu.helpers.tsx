import React from "react";
import { render } from "@testing-library/react";

import Menu from "menu/Menu";
import mockMenuJson from "./mockMenuJson";
import { SettingsContext } from "menu/Contexts";

export default function renderMenu(mockMenuJsonOptions) {
  const onCreateOrder = jest.fn();
  const data = mockMenuJson(mockMenuJsonOptions);
  const { bundles } = data;
  const utils = render(
    <SettingsContext.Provider value={{ showCredits: true, bundles }}>
      <Menu {...data} onCreateOrder={onCreateOrder} />
    </SettingsContext.Provider>
  );

  return { ...utils, onCreateOrder, data };
}
