import React from "react";
import styled from "styled-components";

import AddItemForm from "./AddItemForm";
import CopyFrom from "./CopyFrom";
import MenuItemGrid from "./MenuItemGrid";
import PickupDaysPanel from "./PickupDaysPanel";
import { Button } from "./ui/Button";
import { useApi } from "../Context";
import type { AdminItem, AdminMenuBuilderResponse } from "../../../types/api";

type BuilderLayoutProps = {
  allItems: AdminItem[];
  menu: AdminMenuBuilderResponse;
};

export default function BuilderLayout({ allItems, menu }: BuilderLayoutProps) {
  const api = useApi();
  const [tab, setTab] = React.useState(0);
  const [pickupDayTab, setPickupDayTab] = React.useState(0);
  const [isClearHover, setIsClearHover] = React.useState(false);
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

  const filterItemsByPickupDay = (items: AdminMenuBuilderResponse["items"]) => {
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
    <Root>
      <CopyFrom menuId={menu.id} recentMenus={recentMenus} />
      <hr />
      <PickupDaysPanel pickupDays={pickupDays} leadtimeHours={leadtimeHours} />
      <hr />
      <HeaderRow>
        <h2>Menu Items</h2>
        <Button
          type="button"
          size="sm"
          variant="danger"
          onClick={handleClearAllItems}
          disabled={!hasItems}
          title={hasItems ? "Remove all items" : "No items to clear"}
          onMouseEnter={() => setIsClearHover(true)}
          onMouseLeave={() => setIsClearHover(false)}
        >
          {isClearHover ? "💣 Delete all menu items!" : "💥 Clear all"}
        </Button>
      </HeaderRow>
      <FilterTabs>
        <TabList role="tablist" aria-label="pickup day filters">
          {pickupDayFilters.map((filter, index) => (
            <TabButton
              key={filter.label}
              type="button"
              role="tab"
              aria-selected={pickupDayTab === index}
              active={pickupDayTab === index}
              onClick={() => setPickupDayTab(index)}
              {...pickupDayTabProps(index)}
            >
              {filter.label}
            </TabButton>
          ))}
        </TabList>
      </FilterTabs>
      <FilterTabs>
        <TabList role="tablist" aria-label="menu item filters">
          <TabButton
            type="button"
            role="tab"
            aria-selected={tab === 0}
            active={tab === 0}
            onClick={() => setTab(0)}
            {...a11yProps(0)}
          >
            All menus
          </TabButton>
          <TabButton
            type="button"
            role="tab"
            aria-selected={tab === 1}
            active={tab === 1}
            onClick={() => setTab(1)}
            {...a11yProps(1)}
          >
            Subscribers
          </TabButton>
          <TabButton
            type="button"
            role="tab"
            aria-selected={tab === 2}
            active={tab === 2}
            onClick={() => setTab(2)}
            {...a11yProps(2)}
          >
            Marketplace
          </TabButton>
        </TabList>
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
    </Root>
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
      {value === index && <PanelContent>{children}</PanelContent>}
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

const Root = styled.div`
  flex-grow: 1;
  background: #fff;
`;

const PanelContent = styled.div`
  padding: 0.75rem 0.2rem 0.4rem;
`;

const HeaderRow = styled.div`
  display: flex;
  align-items: center;
  gap: 0.75rem;
  h2 {
    margin: 0;
  }
`;

const FilterTabs = styled.div`
  margin: 0.35rem 0 0.75rem;
  border-bottom: 1px solid #e9e9e9;
`;

const TabList = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 0.2rem;
`;

const TabButton = styled.button<{ active: boolean }>`
  text-transform: none;
  font-weight: 600;
  letter-spacing: 0.02em;
  min-width: 90px;
  padding: 6px 12px;
  border: 0;
  border-bottom: 3px solid
    ${({ active }) => (active ? "#3f3a80" : "transparent")};
  color: ${({ active }) => (active ? "#222" : "#6b6b6b")};
  background: transparent;
  cursor: pointer;

  &:focus-visible {
    outline: 2px solid #3f3a80;
    outline-offset: 1px;
  }
`;
