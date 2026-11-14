import React, { useState, useRef } from "react";
import styled from "styled-components";

import Layout from "./Layout";
import HolidayMenuTab from "./HolidayMenuTab";
import EmailSettings from "./EmailSettings";
import type {
  Menu as MenuType,
  MenuOrder,
  MenuUser,
  MenuOrderRequest,
  MarketplaceOrderRequest,
} from "../../types/api";

type MenuTabsProps = {
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
  initialTab?: string;
};

export default function MenuTabs({
  handleCreateHolidayOrder,
  handleCreateRegularOrder,
  holidayMenu,
  holidayOrder,
  isEditingOrder,
  regularMenu,
  regularOrder,
  setIsEditingOrder,
  user,
  initialTab,
}: MenuTabsProps) {
  // ?tab=email (the unsubscribe and email-preferences links) wins over both
  // menus, the same as it does in Layout when there is no holiday menu.
  const [showEmailSettings, setShowEmailSettings] = useState(
    initialTab === "email"
  );
  const [showHoliday, setShowHoliday] = useState(!regularMenu);
  const regularTabRef = useRef<HTMLButtonElement>(null);
  const holidayTabRef = useRef<HTMLButtonElement>(null);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowRight" || e.key === "ArrowLeft") {
      e.preventDefault();
      setShowHoliday((prev) => {
        const next = !prev;
        if (next) {
          holidayTabRef.current?.focus();
        } else {
          regularTabRef.current?.focus();
        }
        return next;
      });
    }
  };

  if (showEmailSettings && user) {
    return (
      <EmailSettings user={user} onBack={() => setShowEmailSettings(false)} />
    );
  }

  return (
    <>
      <TabBar
        role="tablist"
        aria-label="menu selection"
        onKeyDown={handleKeyDown}
      >
        {regularMenu && (
          <TabButton
            ref={regularTabRef}
            role="tab"
            id="tab-regular"
            aria-selected={!showHoliday}
            aria-controls="panel-regular"
            tabIndex={!showHoliday ? 0 : -1}
            active={!showHoliday}
            onClick={() => setShowHoliday(false)}
          >
            {regularMenu.name}
          </TabButton>
        )}
        <TabButton
          ref={holidayTabRef}
          role="tab"
          id="tab-holiday"
          aria-selected={showHoliday}
          aria-controls="panel-holiday"
          tabIndex={showHoliday ? 0 : -1}
          active={showHoliday}
          onClick={() => setShowHoliday(true)}
        >
          <HolidayBadge aria-hidden="true">Holiday</HolidayBadge>
          <span>{holidayMenu.name}</span>
        </TabButton>
      </TabBar>

      {!showHoliday && regularMenu && (
        <div role="tabpanel" id="panel-regular" aria-labelledby="tab-regular">
          <Layout
            handleCreateOrder={handleCreateRegularOrder}
            isEditingOrder={isEditingOrder}
            menu={regularMenu}
            order={regularOrder}
            setIsEditingOrder={setIsEditingOrder}
            user={user}
          />
        </div>
      )}

      {showHoliday && (
        <div role="tabpanel" id="panel-holiday" aria-labelledby="tab-holiday">
          <HolidayMenuTab
            handleCreateOrder={handleCreateHolidayOrder}
            menu={holidayMenu}
            order={holidayOrder}
            user={user}
          />
        </div>
      )}
    </>
  );
}

const TabBar = styled.div`
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
`;

const TabButton = styled.button<{ active: boolean }>`
  flex: 1;
  min-width: 0;
  padding: 10px 16px;
  background: ${({ active }) => (active ? "#352c63" : "transparent")};
  color: ${({ active }) => (active ? "white" : "#352c63")};
  border: 1.5px solid #352c63;
  border-radius: 4px;
  font-family: "Raleway", sans-serif;
  font-size: 0.95rem;
  font-weight: 500;
  letter-spacing: 0.03em;
  cursor: pointer;
  transition:
    background 0.15s,
    color 0.15s;
  /* Badge stacks above the name, and the name wraps, so a long menu name
     ("Weekly Menu 11/12 - 11/14") never clips at phone width. */
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  text-align: center;
  line-height: 1.25;
  overflow-wrap: anywhere;

  &:hover {
    background: ${({ active }) =>
      active ? "#352c63" : "rgba(53, 44, 99, 0.08)"};
  }

  &:focus-visible {
    outline: 2px solid #352c63;
    outline-offset: 2px;
  }
`;

const HolidayBadge = styled.span`
  flex-shrink: 0;
  font-family: "Oswald", sans-serif;
  font-size: 0.7rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  background: #d5482c;
  color: white;
  padding: 2px 6px;
  border-radius: 2px;
`;
