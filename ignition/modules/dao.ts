import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DAOModule = buildModule("DAOModule", (m) => {
  const dao = m.contract("DecentralizedAdPlatform", ["0x3133A52a8b519311E6C34e98410A7aaA238c84B2", "0x586EE5Df24c5a426e42eD7Ea6e3EB0f00a4a2256"]);

  return { dao };
});

export default DAOModule;