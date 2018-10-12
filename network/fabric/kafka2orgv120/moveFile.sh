#!/usr/bin/env bash
rm -rf bak
mkdir bak
mkdir bak/peer0.org1
mkdir bak/peer1.org1
mkdir bak/peer0.org2
mkdir bak/peer1.org2

sudo mv peer0.org1.example.com/blockfile_000000  bak/peer0/
sudo mv peer1.org1.example.com/blockfile_000000  bak/peer1/

sudo mv peer0.org1.example.com/blockfile_000001  bak/peer0/
sudo mv peer1.org1.example.com/blockfile_000001  bak/peer1/

sudo mv peer0.org2.example.com/blockfile_000000  bak/peer0/
sudo mv peer1.org2.example.com/blockfile_000000  bak/peer1/

sudo mv peer0.org2.example.com/blockfile_000001  bak/peer0/
sudo mv peer1.org2.example.com/blockfile_000001  bak/peer1/

sudo cp bak/peer0/* peer0.org1.example.com/
sudo cp  bak/peer1/* peer1.org1.example.com/
sudo cp bak/peer0/* peer0.org2.example.com/
sudo cp  bak/peer1/* peer1.org2.example.com/