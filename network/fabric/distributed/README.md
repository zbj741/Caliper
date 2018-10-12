# fabricKafka
Kafka based fabric network setup 
Distribute deployment.

1、
主机1：120.92.113.219
主机2：120.92.113.14
主机1上执行：docker-compose -f network/fabric/distributed/machine1.yaml up -d
主机2上执行：node benchmark/simple/main.js -c config-fabric-distributed-machine2.json -n fabric-distributed-machine2.json


2、
主机1：120.92.113.219
主机2：120.92.113.14
主机2上执行：docker-compose -f network/fabric/distributed/machine2.yaml up -d
主机1上执行：node benchmark/simple/main.js -c config-fabric-distributed-machine1.json -n fabric-distributed-machine1.json

