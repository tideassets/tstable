#!/bin/bash

# 读取环境变量
source .env

# 执行命令
node verify.js broadcast/$1.s.sol/$2/run-latest.json
