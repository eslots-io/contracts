call truffle.cmd compile
call truffle-flattener contracts/ESlotsToken.sol > build/ESlotsTokenFlat.sol
call truffle-flattener contracts/SlotMachineGambling.sol > build/SlotMachineGamblingFlat.sol
call truffle-flattener contracts/ESlotsCrowdsale.sol > build/ESlotsCrowdsaleFlat.sol