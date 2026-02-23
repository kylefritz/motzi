import React, { useState } from "react";
import { Tabs, Tab, Box } from "@material-ui/core";
import styled from "styled-components";

import Layout from "./Layout";
import HolidayMenuTab from "./HolidayMenuTab";
import type {
  CreditBundle,
  Menu as MenuType,
  MenuOrder,
  MenuUser,
  MenuOrderRequest,
  MarketplaceOrderRequest,
} from "../../types/api";

type MenuTabsProps = {
  bundles: CreditBundle[];
  handleCreateHolidayOrder: (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => Promise<unknown>;
  handleCreateRegularOrder: (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => Promise<unknown>;
  holidayMenu: MenuType;
  holidayOrder: MenuOrder | null;
  isEditingOrder: boolean;
  regularMenu: MenuType | null;
  regularOrder: MenuOrder | null;
  setIsEditingOrder: React.Dispatch<React.SetStateAction<boolean>>;
  user: MenuUser | null;
};

function a11yProps(index: number) {
  return {
    id: `menu-tab-${index}`,
    "aria-controls": `menu-tabpanel-${index}`,
  };
}

type TabPanelProps = React.HTMLAttributes<HTMLDivElement> & {
  children: React.ReactNode;
  value: number;
  index: number;
};

function TabPanel({ children, value, index, ...other }: TabPanelProps) {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`menu-tabpanel-${index}`}
      aria-labelledby={`menu-tab-${index}`}
      {...other}
    >
      {value === index && <Box>{children}</Box>}
    </div>
  );
}

export default function MenuTabs({
  bundles,
  handleCreateHolidayOrder,
  handleCreateRegularOrder,
  holidayMenu,
  holidayOrder,
  isEditingOrder,
  regularMenu,
  regularOrder,
  setIsEditingOrder,
  user,
}: MenuTabsProps) {
  // Default to holiday tab when there's no regular menu this week
  const [activeTab, setActiveTab] = useState(regularMenu ? 0 : 1);

  const handleChange = (_event: React.ChangeEvent<{}>, newValue: number) => {
    setActiveTab(newValue);
  };

  return (
    <div>
      <MenuTabBar>
        <Tabs
          value={activeTab}
          onChange={handleChange}
          aria-label="menu selection"
        >
          {regularMenu && <Tab label="Weekly Menu" {...a11yProps(0)} />}
          <Tab
            label={
              <span>
                {!holidayOrder && <HolidayLabel>Holiday</HolidayLabel>}
                {holidayMenu.name}
              </span>
            }
            {...a11yProps(regularMenu ? 1 : 0)}
          />
        </Tabs>
      </MenuTabBar>

      {regularMenu && (
        <TabPanel value={activeTab} index={0}>
          <Layout
            bundles={bundles}
            handleCreateOrder={handleCreateRegularOrder}
            isEditingOrder={isEditingOrder}
            menu={regularMenu}
            order={regularOrder}
            setIsEditingOrder={setIsEditingOrder}
            user={user}
          />
        </TabPanel>
      )}

      <TabPanel value={activeTab} index={regularMenu ? 1 : 0}>
        <HolidayMenuTab
          bundles={bundles}
          handleCreateOrder={handleCreateHolidayOrder}
          menu={holidayMenu}
          order={holidayOrder}
          user={user}
        />
      </TabPanel>
    </div>
  );
}

const MenuTabBar = styled.div`
  margin: 0 0 1.75rem;
  border-bottom: 1px solid #e0d0b8;

  .MuiTabs-indicator {
    height: 2px;
    background-color: #352c63;
  }

  .MuiTab-root {
    text-transform: none;
    font-family: 'Raleway', sans-serif;
    font-weight: 500;
    font-size: 0.95rem;
    letter-spacing: 0.02em;
    min-width: 0;
    padding: 10px 24px 10px 0;
    color: #9e8c7a;
    opacity: 1;
    align-items: flex-end;
  }

  .MuiTab-textColorInherit {
    color: #9e8c7a;
    opacity: 1;
  }

  .Mui-selected {
    color: #352c63;
  }

  .MuiTabs-root {
    min-height: 44px;
  }
`;

const HolidayLabel = styled.span`
  display: block;
  font-family: 'Oswald', sans-serif;
  font-size: 0.6rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #d54a2c;
  margin-bottom: 2px;
`;
