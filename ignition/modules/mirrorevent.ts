import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MirrorModule = buildModule("MirrorModule", (m) => {
  const mirror = m.contract("mirrorEvent");

  return { mirror };
});

export default MirrorModule;