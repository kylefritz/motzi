import React, { useContext } from "react";

const ApiContext = React.createContext();

export { ApiContext };

export function useApi() {
  return useContext(ApiContext);
}
