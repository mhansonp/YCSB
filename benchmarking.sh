#!/usr/bin/env bash
set -e

if [ -z $1 ] || [ -z $2 ]; then
    echo "Usage ./benchmarking <cluster-operator-user> <cluster-operator-password>"
    exit 1
fi

USER_LOGIN=$1
USER_PASSWORD=$2
filename=""

destroy_region()
{
echo "destory region"
    gfsh -e "connect  --locator=10.74.37.195[55221] --user=$USER_LOGIN --password=$USER_PASSWORD" -e "destroy region --name=/usertable" > $filename
}

create_region()
{
echo "create region"
    gfsh -e "connect  --locator=10.74.37.195[55221] --user=$USER_LOGIN --password=$USER_PASSWORD" -e "create region --name=usertable --type=$1" >> $filename
}

describe_region()
{
echo "describe region"
    gfsh -e "connect  --locator=10.74.37.195[55221] --user=$USER_LOGIN --password=$USER_PASSWORD" -e "describe region --name=usertable" >> $filename
}

load_workload()
{
echo "load workload"
    ./bin/ycsb load geode -P workloads/$1 -p geode.locator=10.74.37.195[55221] -p security-username=$USER_LOGIN -p security-password=$USER_PASSWORD | grep -e "^[[A-Z]\w*]" >> $filename
}

run_workload()
{
echo "run workload"
    ./bin/ycsb run  geode -P workloads/$1 -p geode.locator=10.74.37.195[55221] -p security-username=$USER_LOGIN -p security-password=$USER_PASSWORD -target 1000000 -threads 30 -p measurementtype=timeseries -p timeseries.granularity=2000 | grep -e "^[[A-Z]\w*]" >> $filename
}

run_a_set()
{
counter=0
    if ! [ -d benchmark_logs ]; then
	mkdir -p benchmark_logs
    fi
    while [ $counter -lt 5 ];
    do
	echo "running a set of workload: $2 with persistence set to $1"
	filename="benchmark_logs/pass-$counter-$1-$2"
	destroy_region
	create_region $1
	describe_region
	load_workload $2
	run_workload $2
let counter=$counter+1
    done
}

run_a_set PARTITION_PERSISTENT workloada
run_a_set PARTITION workloada_small
run_a_set PARTITION workloadb
run_a_set PARTITION_PERSISTENT workloadb
