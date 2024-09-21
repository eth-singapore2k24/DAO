import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TempDAOModule = buildModule("TempDAOModule", (m) => {
//   const dao = m.contract("TempDecentralizedAdPlatform", ["0x3133A52a8b519311E6C34e98410A7aaA238c84B2", "0x586EE5Df24c5a426e42eD7Ea6e3EB0f00a4a2256"]);
    const dao = m.contract("TempDecentralizedAdPlatform", ["abc"]);

  return { dao };
});

export default TempDAOModule;