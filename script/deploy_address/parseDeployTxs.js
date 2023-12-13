const fs = require("fs");
const path = require("path");

// 获取命令行参数
const [, , inputFilePath, outputFilePath] = process.argv;

// 检查文件路径是否已提供
if (!inputFilePath || !outputFilePath) {
  console.error("Please provide input and output file paths");
  process.exit(1);
}

// 读取文件
fs.readFile(path.resolve(inputFilePath), "utf8", (err, data) => {
  if (err) {
    console.error(err);
    return;
  }

  // 解析 JSON 数据
  const jdata = JSON.parse(data);

  // 过滤出所有的 "CREATE" 交易
  const createTransactions = jdata.transactions.filter(
    (transaction) => transaction.transactionType === "CREATE"
  );

  // 将结果格式化为 {contractName: contractAddress} 的形式
  const result = createTransactions.reduce((acc, transaction) => {
    acc[transaction.contractName] = transaction.contractAddress;
    return acc;
  }, {});

  // 将结果写入新的文件
  fs.writeFile(
    path.resolve(outputFilePath),
    JSON.stringify(result, null, 2),
    "utf8",
    (err) => {
      if (err) {
        console.error(err);
        return;
      }

      console.log("File has been created");
    }
  );
});
