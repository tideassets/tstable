#!/bin/bash

# 读取环境变量
source .env

# 执行命令
forge script script/$1.s.sol:$2 --fork-url $RPC_URL --broadcast --lib-paths lib/ds-libs/lib --slow
