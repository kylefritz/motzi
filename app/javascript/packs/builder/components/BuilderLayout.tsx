import React from "react";
import { Tabs, Tab, Box } from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";
import styled from "styled-components";

import AddItemForm from "./AddItemForm";
import CopyFrom from "./CopyFrom";
import MenuItemGrid from "./MenuItemGrid";
import PickupDaysPanel from "./PickupDaysPanel";
import { useApi } from "../Context";
import type { AdminItem, AdminMenuBuilderResponse } from "../../../types/api";

type BuilderLayoutProps = {
  allItems: AdminItem[];
  menu: AdminMenuBuilderResponse;
};

export default function BuilderLayout({
  allItems,
  menu,
}: BuilderLayoutProps) {
  const classes = useStyles();
  const api = useApi();
  const [tab, setTab] = React.useState(0);
  const [pickupDayTab, setPickupDayTab] = React.useState(0);
  const [isClearHover, setIsClearHover] = React.useState(false);
  const handleChange = (_event: React.ChangeEvent<{}>, newTab: number) => {
    setTab(newTab);
  };
  const handlePickupDayChange = (
    _event: React.ChangeEvent<{}>,
    newTab: number
  ) => {
    setPickupDayTab(newTab);
  };
  const { pickupDays, leadtimeHours, recentMenus } = menu;
  const hasItems = menu.items.length > 0;
  const pickupDayFilters = [
    { label: "All days", pickupAt: null },
    ...pickupDays.map((pickupDay) => ({
      label: pickupDay.debug || pickupDay.deadlineText || pickupDay.pickupAt,
      pickupAt: pickupDay.pickupAt,
    })),
  ];
  const activePickupAt = pickupDayFilters[pickupDayTab]?.pickupAt || null;

  const filterItemsByPickupDay = (
    items: AdminMenuBuilderResponse["items"]
  ) => {
    if (!activePickupAt) {
      return items;
    }
    return items.filter((item) =>
      item.pickupDays.some((day) => day.pickupAt === activePickupAt)
    );
  };

  function handleClearAllItems() {
    if (!hasItems) {
      return;
    }
    const confirmed = window.confirm(
      "Remove all items from this menu? This cannot be undone."
    );
    if (!confirmed) {
      return;
    }
    api.item.clearAll();
  }
  return (
    <div className={classes.root}>
      <CopyFrom menuId={menu.id} recentMenus={recentMenus} />
      <hr />
      <PickupDaysPanel pickupDays={pickupDays} leadtimeHours={leadtimeHours} />
      <hr />
      <HeaderRow>
        <h2>Menu Items</h2>
        <ClearBtn
          type="button"
          onClick={handleClearAllItems}
          disabled={!hasItems}
          title={hasItems ? "Remove all items" : "No items to clear"}
          onMouseEnter={() => setIsClearHover(true)}
          onMouseLeave={() => setIsClearHover(false)}
        >
          {isClearHover ? "💣 Delete all menu items!": "💥 Clear all"}
        </ClearBtn>
      </HeaderRow>
      <FilterTabs>
        <Tabs
          value={pickupDayTab}
          onChange={handlePickupDayChange}
          aria-label="pickup day filters"
        >
          {pickupDayFilters.map((filter, index) => (
            <Tab
              key={filter.label}
              label={filter.label}
              {...pickupDayTabProps(index)}
            />
          ))}
        </Tabs>
      </FilterTabs>
      <FilterTabs>
        <Tabs
          value={tab}
          onChange={handleChange}
          aria-label="menu item filters"
        >
          <Tab label="All menus" {...a11yProps(0)} />
          <Tab label="Subscribers" {...a11yProps(1)} />
          <Tab label="Marketplace" {...a11yProps(2)} />
        </Tabs>
      </FilterTabs>
      <TabPanel value={tab} index={0}>
        <MenuItemGrid
          {...{ menuItems: filterItemsByPickupDay(menu.items), pickupDays }}
        />
      </TabPanel>
      <TabPanel value={tab} index={1}>
        <MenuItemGrid
          {...{
            menuItems: filterItemsByPickupDay(
              menu.items.filter((i) => i.subscriber)
            ),
            pickupDays,
          }}
        />
      </TabPanel>
      <TabPanel value={tab} index={2}>
        <MenuItemGrid
          {...{
            menuItems: filterItemsByPickupDay(
              menu.items.filter((i) => i.marketplace)
            ),
            pickupDays,
          }}
        />
      </TabPanel>

      <AddItemForm
        items={allItems}
        not={menu.items.map(({ name }) => name)}
        pickupDays={menu.pickupDays}
      />
    </div>
  );
}

type TabPanelProps = React.HTMLAttributes<HTMLDivElement> & {
  children: React.ReactNode;
  value: number;
  index: number;
};

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
    >
      {value === index && <Box p={3}>{children}</Box>}
    </div>
  );
}

function a11yProps(index: number) {
  return {
    id: `simple-tab-${index}`,
    "aria-controls": `simple-tabpanel-${index}`,
  };
}

function pickupDayTabProps(index: number) {
  return {
    id: `pickup-day-tab-${index}`,
    "aria-controls": `pickup-day-tabpanel-${index}`,
  };
}

const useStyles = makeStyles((theme) => ({
  root: {
    flexGrow: 1,
    backgroundColor: theme.palette.background.paper,
  },
}));

const HeaderRow = styled.div`
  display: flex;
  align-items: center;
  gap: 0.75rem;
  h2 {
    margin: 0;
  }
`;

const ClearBtn = styled.button`
  margin-left: 0.25rem;
  padding: 0.2rem 0.6rem;
  font-size: 90%;
  border: 1px solid #c7372f;
  background: #fff;
  color: #c7372f;
  border-radius: 4px;

  &:hover:not(:disabled) {
    background: #c7372f;
    color: #fff;
  }

  &:disabled {
    color: #8a8a8a;
    background: #f4f4f4;
    border-color: #d0d0d0;
    cursor: not-allowed;
  }
`;

const FilterTabs = styled.div`
  margin: 0.35rem 0 0.75rem;
  border-bottom: 1px solid #e9e9e9;

  .MuiTabs-indicator {
    height: 3px;
    background-color: #3f3a80;
  }

  .MuiTab-root {
    text-transform: none;
    font-weight: 600;
    letter-spacing: 0.02em;
    min-width: 90px;
    padding: 6px 12px;
  }

  .MuiTab-textColorInherit {
    color: #6b6b6b;
  }

  .Mui-selected {
    color: #222;
  }
`;
