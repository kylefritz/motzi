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
                {holidayMenu.name}
                {!holidayOrder && (
                  <NewBadge>New</NewBadge>
                )}
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
  margin: 0 0 1.5rem;
  border-bottom: 1px solid #e9e9e9;

  .MuiTabs-indicator {
    height: 3px;
    background-color: #3f3a80;
  }

  .MuiTab-root {
    text-transform: none;
    font-weight: 600;
    letter-spacing: 0.02em;
    min-width: 120px;
    padding: 8px 16px;
  }

  .MuiTab-textColorInherit {
    color: #6b6b6b;
  }

  .Mui-selected {
    color: #222;
  }
`;

const NewBadge = styled.span`
  margin-left: 6px;
  font-size: 0.7rem;
  font-weight: 700;
  background: #e8f5e9;
  color: #2e7d32;
  padding: 1px 6px;
  border-radius: 8px;
  vertical-align: middle;
`;
