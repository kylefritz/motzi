import React from "react";
import styled from "styled-components";
import { AppBar, Tabs, Tab, Box } from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";

import MenuItem from "./Item";
import Adder from "./Adder";
import { PickupDays } from "./PickupDay";

export default function SimpleTabs({
  allItems,
  menu,
  handleAddItem,
  handleRemoveItem,
  handleAddPickupDay,
  handleRemovePickupDay,
  handleChangeMenuItemPickupDay,
}) {
  const classes = useStyles();
  const [tab, setTab] = React.useState(0);
  const isSubscriber = tab === 0;
  const handleChange = (event, newTab) => {
    setTab(newTab);
  };

  const subscriber = menu.items.filter((i) => i.subscriber);
  const marketplace = menu.items.filter((i) => i.marketplace);

  function makeItemsGrid(menuItems) {
    return (
      <ItemGrid
        {...{
          menuItems,
          handleRemoveItem,
          pickupDays: menu.pickupDays,
          handleChangeMenuItemPickupDay,
        }}
      />
    );
  }

  return (
    <div className={classes.root}>
      <AppBar position="static">
        <Tabs
          value={tab}
          onChange={handleChange}
          aria-label="simple tabs example"
        >
          <Tab label="Subscribers" {...a11yProps(0)} />
          <Tab label="Marketplace" {...a11yProps(1)} />
        </Tabs>
      </AppBar>
      <TabPanel value={tab} index={0}>
        {makeItemsGrid(subscriber)}
      </TabPanel>
      <TabPanel value={tab} index={1}>
        {makeItemsGrid(marketplace)}
      </TabPanel>

      <Adder
        items={allItems}
        not={(isSubscriber ? subscriber : marketplace).map(({ name }) => name)}
        pickupDays={menu.pickupDays}
        onAdd={(item) => handleAddItem(item)}
      />
      <PickupDays {...{ ...menu, handleAddPickupDay, handleRemovePickupDay }} />
    </div>
  );
}

function TabPanel(props) {
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

function ItemGrid({
  menuItems,
  pickupDays,
  handleRemoveItem,
  handleChangeMenuItemPickupDay,
}) {
  if (items.length == 0) {
    return (
      <p>
        <em>no items</em>
      </p>
    );
  }
  return (
    <Grid>
      {menuItems.map((i) => (
        <MenuItem
          key={i.menuItemId}
          {...{
            ...i,
            handleChangeMenuItemPickupDay,
          }}
          menuPickupDays={pickupDays}
          onRemove={() => handleRemoveItem(i.itemId)}
        />
      ))}
    </Grid>
  );
}

function a11yProps(index) {
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

const Grid = styled.div`
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
`;
