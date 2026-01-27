import React, { useContext } from "react";

const ApiContext = React.createContext<any>(null);

export { ApiContext };

export function useApi() {
  return useContext(ApiContext);
}
