const fs = require('fs');

let sourceFile = process.argv[2];
let targetFile = process.argv[3];

// 读取并解析JSON数据
let data = JSON.parse(fs.readFileSync(sourceFile, 'utf-8'));
let newData = {};

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
newData.tokens = tokensArray;
newData.import = data.import;
let global = {};
/*
 "description": "Mainnet deployment",
  "pauseDelay": "0",
  "vat_line": "778000000",
  "vow_wait": "561600",
  "vow_dump": "250",
  "vow_sump": "50000",
  "vow_bump": "10000",
  "vow_hump": "500000",
  "cat_box": "10000000",
  "dog_hole": "100000000",
  "jug_base": "0",
  "pot_dsr": "0",
  "cure_wait": "0",
  "end_wait": "262800",
  "esm_min": "100000",
  "flap_beg": "2",
  "flap_ttl": "1800",
  "flap_tau": "259200",
  "flap_lid": "150000",
  "flop_beg": "3",
  "flop_pad": "20",
  "flop_ttl": "21600",
  "flop_tau": "259200",
  "flash_max": "500000000",
  */
global.description = data.description;
global.pauseDelay = data.pauseDelay;
global.vat_line = data.vat_line;
global.vow_wait = data.vow_wait;
global.vow_dump = data.vow_dump;
global.vow_sump = data.vow_sump;
global.vow_bump = data.vow_bump;
global.vow_hump = data.vow_hump;
global.cat_box = data.cat_box;
global.dog_hole = data.dog_hole;
global.jug_base = data.jug_base;
global.pot_dsr = data.pot_dsr;
global.cure_wait = data.cure_wait;
global.end_wait = data.end_wait;
global.esm_min = data.esm_min;
global.flap_beg = data.flap_beg;
global.flap_ttl = data.flap_ttl;
global.flap_tau = data.flap_tau;
global.flap_lid = data.flap_lid;
global.flop_beg = data.flop_beg;
global.flop_pad = data.flop_pad;
global.flop_ttl = data.flop_ttl;
global.flop_tau = data.flop_tau;
global.flash_max = data.flash_max;
newData.global = global;

// 将新的JSON数据写回文件
fs.writeFileSync(targetFile, JSON.stringify(newData, null, 2));