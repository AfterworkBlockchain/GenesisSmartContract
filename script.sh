#!/bin/bash

rm GenesisSpace.*
solc --abi genesis.sol -o .
solc --bin genesis.sol -o .
./abigen --bin=GenesisSpace.bin --abi=GenesisSpace.abi --pkg=GenesisSpace --out=GenesisSpace.go

