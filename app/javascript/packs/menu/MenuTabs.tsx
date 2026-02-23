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
                  <NewBadge>Holiday</NewBadge>
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
  margin: 0 0 1.75rem;
  border-bottom: 2px solid #e8d9c4;

  .MuiTabs-indicator {
    height: 3px;
    background-color: #3f3a80;
    border-radius: 3px 3px 0 0;
  }

  .MuiTab-root {
    text-transform: none;
    font-weight: 600;
    font-size: 1rem;
    letter-spacing: 0.01em;
    min-width: 130px;
    padding: 10px 20px;
    color: #8b7355;
    opacity: 1;
  }

  .MuiTab-textColorInherit {
    color: #8b7355;
    opacity: 0.75;
  }

  .Mui-selected {
    color: #3f3a80;
    opacity: 1;
  }

  .MuiTabs-root {
    min-height: 44px;
  }
`;

const NewBadge = styled.span`
  margin-left: 7px;
  font-size: 0.65rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  background: #fff3e0;
  color: #b45309;
  border: 1px solid #f0c070;
  padding: 2px 7px;
  border-radius: 3px;
  vertical-align: middle;
  position: relative;
  top: -1px;
`;
