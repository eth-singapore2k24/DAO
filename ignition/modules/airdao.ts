import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const AIRDAOModule = buildModule("AIRDAOModule", (m) => {
  const airdao = m.contract("AirDAOSBT");

  return { airdao };
});

export default AIRDAOModule;
