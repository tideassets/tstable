#!/bin/bash

# 读取环境变量
source .env

# 执行命令
node verify.js broadcast/deploy.s.sol/421614/run-latest.json
