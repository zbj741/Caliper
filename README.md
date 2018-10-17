## Caliper Introduction

Caliper is a blockchain performance benchmark framework, which allows users to test different blockchain solutions with predefined use cases, and get a set of performance test results.

Currently supported blockchain solutions:
* [fabric v1.0+](https://github.com/hyperledger/fabric), the lastest version that has been verified is v1.1.0
* [sawtooth 1.0+](https://github.com/hyperledger/sawtooth-core)
* [Iroha 1.0 beta-3](https://github.com/hyperledger/iroha)

Hyperledger Composer is also supported, please see [Composer Performance Test](./docs/Composer.md).

Currently supported performance indicators:
* Success rate
* Transaction/Read throughput
* Transaction/Read latency(minimum, maximum, average, percentile)
* Resource consumption (CPU, Memory, Network IO,...)

See [to add the link to PSWG] to find out the definitions and corresponding measurement methods.  

## Achitecture
See [Architecture introduction](docs/Architecture.md).

## Build

### Pre-requisites

Make sure following tools are installed
* NodeJS 8.X
* node-gyp
* Docker
* Docker-compose

Run `npm install` in caliper folder to install dependencies locally

### Install blockchain SDKs
* Fabric
  * Install using the repository
    * run `npm install grpc@1.10.1 fabric-ca-client fabric-client` in the root folder
    * If you want to test fabric with old version such as v1.1.0, you should install compatible client SDK,  
    e.g. `npm install fabric-ca-client@1.1.0 fabric-client@1.1.0`

* Sawtooth
  * Install dependencies

    ```
    $npm install protocol-buffers
    ```
  * Install sawtooth javascript sdk using repository
    * run `npm install sawtooth-sdk` in the root folder

* Iroha
  * Install Iroha Library by `npm install --no-save iroha-lib@0.1.7` in Caliper's root folder.
  * The package is in **alfa phase**, so if you have some problems with installing or compilation - please contact [Iroha maintainers](https://github.com/hyperledger/iroha/issues).

* Composer
   * Install dependencies

   The easiest way to get started using a target version of Composer is to update the main package.json file to include the required Composer and Fabric modules, and subsequently run an `npm install` command. It is important that the Composer and Fabric versions are compatible.

   ```
    "composer-admin": "0.19.0",
    "composer-client": "0.19.0",
    "composer-common": "0.19.0",
    "fabric-ca-client": "1.1.0",
    "fabric-client": "1.1.0",
   ```

   Please see the plugin [documentation](./docs/Composer.md) for more details on using the Composer performance plugin, and developing your own tests.

## Run benchmark

All predefined benchmarks can be found in [*benchmark*](./benchmark) folder.
To start your first benchmark, just run this in root folder
```bash
node benchmark/simple/main.js -c yourconfig.json -n yournetwork.json
```
* -c : specify the config file of the benchmark, if not used,  *config.json* will be used as default.
* -n : specify the config file of the blockchain network under test. If not used, the file address must be specified in the benchmak config file.

Some example SUTs are provided in [*network*](./network) folder, they can be launched automatically before the test by setting the bootstrap commands in the configuration file, e.g
```json
{
  "command" : {
    "start": "docker-compose -f network/fabric/simplenetwork/docker-compose.yaml up -d",
    "end" : "docker-compose -f network/fabric/simplenetwork/docker-compose.yaml down;docker rm $(docker ps -aq)"
  }
}
```
The scripts defined in *command.start* will be called before the test, and the scripts defined in *command.end* will be called after the finish of all tests. You can use them to define any preparation or clean-up works.  

You can also run the test with your own blockchain network, a network configuration should be provided and corresponding file path should be specified in  configuration file's *blockchain.config*.

Note:
* When running the benchmark, one or more blockchain clients will be used to generate and submit transactions to the SUT. The number of launched clients as well as testing workload can be defined using the [configuration file](./docs/Architecture.md#configuration-file).  
* A HTML report will be generated automatically after the testing.

**Alternative**

You can also use npm scripts to run a benchmark.
* npm run list: list all available benchmarks
```bash
$ npm run list

> caliper@0.1.0 list /home/hurf/caliper
> node ./scripts/list.js

Available benchmarks:
drm
simple
```

* npm test: run a benchmark with specific config files
```bash
$ npm test -- simple -c ./benchmark/simple/config.json -n ./benchmark/simple/fabric.json

> caliper@0.1.0 test /home/hurf/caliper
> node ./scripts/test.js "simple" "-c" "./benchmark/simple/config.json" "-n" "./benchmark/simple/fabric.json"
......
```
## Run benchmark with distributed clients (experimental)

In this way, multiple clients can be launched on distributed hosts to run the same benchmark.

1. Start the ZooKeeper service
2. Launch clients on target machines separately by running `node ./src/comm/client/zoo-client.js zookeeper-server` or `npm run startclient -- zookeeper-server` . Time synchronization between target machines should be executed before launching the clients.  

    Example:
    ```bash
    $ npm run startclient -- 10.229.42.159:2181

    > caliper@0.1.0 startclient /home/hurf/caliper
    > node ./src/comm/client/zoo-client.js "10.229.42.159:2181"

    Connected to ZooKeeper
    Created client node:/caliper/clients/client_1514532063571_0000000006
    Created receiving queue at:/caliper/client_1514532063571_0000000006_in
    Created sending queue at:/caliper/client_1514532063571_0000000006_out
    Waiting for messages at:/caliper/client_1514532063571_0000000006_in......
    ```
3. Modify the client type setting in configuration file to 'zookeeper'.

    Example:
    ```
    "clients": {
      "type": "zookeeper",
      "zoo" : {
        "server": "10.229.42.159:2181",
        "clientsPerHost": 5
      }
    }
    ```

4. Launch the benchmark on any machine as usual.

Note:
* Zookeeper is used to register clients and exchange messages. A launched client will add a new znode under /caliper/clients/. The benchmark checks the directory to learn how many clients are there, and assign tasks to each client according to the workload.
* There is no automatic time synchronization between the clients. You should manually synchronize time between target machines, for example using 'ntpdate'.
* The blockchain configuration file must exist on machines which run the client, and the relative path (relative to the caliper folder) of the file must be identical. All referenced files in the configuration must also exist.   




## Write your own benchmarks
Caliper provides a set of nodejs NBIs (North Bound Interfaces) for applications to interact with backend blockchain system. Check the [*src/comm/blockchain.js*](./src/comm/blockchain.js) to learn about the NBIs. Multiple *Adaptors* are implemented to translate the NBIs to different blockchain protocols. So developers can write a benchmark once, and run it with different blockchain systems.

Generally speaking, to write a new caliper benchmark, you need to:
* Write smart contracts for systems you want to test
* Write a testing flow using caliper NBIs. Caliper provides a default benchmark engine, which is pluggable and configurable to integrate new tests easily. For more details, please refer to [Benchmark Engine](./docs/Architecture.md#benchmark-engine) .
* Write a configuration file to define the backend network and benchmark arguments.

## Directory Structure
**Directory** | **Description**
------------------ | --------------
/benchmark | Samples of the blockchain benchmarks
/docs | Documents
/network | Boot configuration files used to deploy some predefined blockchain network under test.
/src | Souce code of the framework
/src/contract | Smart contracts for different blockchain systems

## How to contribute

See [Contributing](/CONTRIBUTING.md)

## License
The Caliper codebase is release under the [Apache 2.0 license](./LICENSE). Any documentation developed by the Caliper Project is licensed under the Creative Commons Attribution 4.0 International License. You may obtain a copy of the license, titled CC-BY-4.0, at http://creativecommons.org/licenses/by/4.0/.
# Caliper

一、删除账本操作

1.启动Caliper solo2orgv120模式测试

进入Caliper文件夹

cd caliper

执行

node benchmark/simple/main.js -c config-fabric-solo2orgv120.json -n fabric-solo2orgv120.json

2.进入各个peer容器中，分别开4个终端，分别进入peer0.org1,peer1.org1,peer0.org2,peer1.org2容器中

终端1：docker exec -it peer0.org1.example.com /bin/bash

终端2：docker exec -it peer0.org2.example.com /bin/bash

终端3：docker exec -it peer1.org1.example.com /bin/bash

终端4：docker exec -it peer1.org2.example.com /bin/bash

3.进入账本目录

这里以终端1为例，其他3个终端操作类似

cd /var/hyperledger/production/ledgersData/chains/chains/mychannel

4.删除账本

rm -rf blockfile_000000

二、配置cli并查询

1.进入caliper目录下执行

vim network/fabric/solo2orgv120/docker-compose.yaml

在打开的配置文件中底部加入cli配置信息

cli1:
container_name: cli1
image: hyperledger/fabric-tools:1.2.0
tty: true
environment:
- GOPATH=/opt/gopath
- CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
- CORE_LOGGING_LEVEL=info
- CORE_PEER_ID=cli
- CORE_PEER_ADDRESS=peer0.org1.example.com:7051
- CORE_PEER_LOCALMSPID=Org1MSP
- CORE_PEER_LOCALMSPTYPE=bccsp
- CORE_PEER_TLS_ENABLED=true
- CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt
- CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
- CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
- CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
- CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=solo2orgv120_default
- CHAINNAME = mychannel
- GODEBUG=netdns=go
working_dir: /opt/gopath/src/github.com/hyperledger/fabric
volumes:
- /var/run/:/host/var/run/
- ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
depends_on:
- orderer.example.com
- peer0.org1.example.com
- peer1.org1.example.com
- peer0.org2.example.com
- peer1.org2.example.com

cli2:
container_name: cli2
image: hyperledger/fabric-tools:1.2.0
tty: true
environment:
- GOPATH=/opt/gopath
- CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
- CORE_LOGGING_LEVEL=info
- CORE_PEER_ID=cli
- CORE_PEER_ADDRESS=peer0.org2.example.com:7051
- CORE_PEER_LOCALMSPID=Org2MSP
- CORE_PEER_LOCALMSPTYPE=bccsp
- CORE_PEER_TLS_ENABLED=true
- CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.crt
- CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key
- CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
- CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
- CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=solo2orgv120_default
- CHAINNAME = mychannel
- GODEBUG=netdns=go
working_dir: /opt/gopath/src/github.com/hyperledger/fabric
volumes:
- /var/run/:/host/var/run/
- ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
depends_on:
- orderer.example.com
- peer0.org1.example.com
- peer1.org1.example.com
- peer0.org2.example.com
- peer1.org2.example.com

3.启动Caliper solo2orgv120模式测试

执行 node benchmark/simple/main.js -c config-fabric-solo2orgv120.json -n fabric-solo2orgv120.json

4.进入cli容器中

终端1：docker exec -it cli1 /bin/bash

终端2：docker exec -it cli2 /bin/bash

5.在cli中查询

peer chaincode query -C mychannel -n simple -c '{"Args":["query","key"]}'

注意：key需要替换为待查询的键值。
