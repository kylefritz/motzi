import React from "react";
import { AppBar, Tabs, Tab, Box } from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";

import AddItemForm from "./AddItemForm";
import CopyFrom from "./CopyFrom";
import MenuItemGrid from "./MenuItemGrid";
import PickupDaysPanel from "./PickupDaysPanel";
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
  const [tab, setTab] = React.useState(0);
  const handleChange = (_event: React.ChangeEvent<{}>, newTab: number) => {
    setTab(newTab);
  };
  const { pickupDays, leadtimeHours, recentMenus } = menu;
  return (
    <div className={classes.root}>
      <CopyFrom menuId={menu.id} recentMenus={recentMenus} />
      <hr />
      <PickupDaysPanel pickupDays={pickupDays} leadtimeHours={leadtimeHours} />
      <hr />
      <h2>Menu Items</h2>
      <AppBar position="static">
        <Tabs
          value={tab}
          onChange={handleChange}
          aria-label="simple tabs example"
        >
          <Tab label="All" {...a11yProps(0)} />
          <Tab label="Subscribers" {...a11yProps(1)} />
          <Tab label="Marketplace" {...a11yProps(2)} />
        </Tabs>
      </AppBar>
      <TabPanel value={tab} index={0}>
        <MenuItemGrid {...{ menuItems: menu.items, pickupDays }} />
      </TabPanel>
      <TabPanel value={tab} index={1}>
        <MenuItemGrid
          {...{
            menuItems: menu.items.filter((i) => i.subscriber),
            pickupDays,
          }}
        />
      </TabPanel>
      <TabPanel value={tab} index={2}>
        <MenuItemGrid
          {...{
            menuItems: menu.items.filter((i) => i.marketplace),
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

const useStyles = makeStyles((theme) => ({
  root: {
    flexGrow: 1,
    backgroundColor: theme.palette.background.paper,
  },
}));
