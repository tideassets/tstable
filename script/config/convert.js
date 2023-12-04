const fs = require('fs');

// 读取并解析JSON数据
let data = JSON.parse(fs.readFileSync('main.json', 'utf-8'));

// 将"tokens"对象转换为数组
let tokensArray = [];
for (let token in data.tokens) {
  let newToken = data.tokens[token];
  let ilks = [];
  for (let ilk in newToken.ilks) {
    let newIlk = newToken.ilks[ilk];
    newIlk.name = ilk;
    ilks.push(newIlk);
  }
  newToken.ilks = ilks;   // 将原来的"ilks"对象保存为"ilks"属性
  newToken.name = token;  // 将原来的键（如"ETH"）保存为"name"属性
  tokensArray.push(newToken);
}

// 替换原来的"tokens"对象为新的数组
data.tokens = tokensArray;

// 将新的JSON数据写回文件
fs.writeFileSync('config.json', JSON.stringify(data, null, 2));