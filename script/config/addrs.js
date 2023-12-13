const fs = require("fs");
const path = require("path");

// 获取命令行参数
const [, , jsonIn, jsonOut] = process.argv;

// 读取 JSON 文件
const data = fs.readFileSync(path.resolve(jsonIn), "utf8");

// 解析 JSON 数据
const jdata = JSON.parse(data);

// 过滤出所有的 "CREATE" 交易
const createTransactions = jdata.transactions.filter(
  (transaction) => transaction.transactionType === "CREATE"
);

// 将结果格式化为数组
// 将结果格式化为数组
const contracts = createTransactions.map((transaction) => ({
  name: transaction.contractName,
  addr: transaction.contractAddress,
}));

fs.writeFileSync(path.resolve(jsonOut), JSON.stringify(contracts, null, 2));
