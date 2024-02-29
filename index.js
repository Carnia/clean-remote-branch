#! node
const inquirer = require('inquirer');
const path = require('path');
const { spawn } = require('child_process');

const format = {
  one_years_ago: '1年前',
  six_months_ago: '180天前',
  three_months_ago: '90天前',
  two_months_ago: '60天前',
  one_months_ago: '30天前',
  current_time: '当前',
  branch_all: '所有分支',
  branch_merged: '已合并',
  branch_no_merged: '未合并',
};

const question = [
  {
    type: 'input',
    message: '1/4）要删除的分支名称中需包含的字符（输入""则不进行该过滤；使用空格添加多个）：',
    name: 'include_filters',
    default: 'feat-',
  },
  {
    type: 'input',
    message: '24）忽略的分支名称中需包含的字符（输入""则不进行该过滤；使用空格添加多个）：',
    name: 'excluded_filters',
    default: 'develop- release-',
  },
  {
    type: 'list',
    message: '3/4）应用日期范围：',
    name: 'date_range',
    choices: [
      'one_years_ago',
      'six_months_ago',
      'three_months_ago',
      'two_months_ago',
      // 'one_months_ago',
      // 'current_time',
    ],
    default: 'six_months_ago',
  },
  {
    type: 'list',
    message: '4/4）获取远程分支范围（全部、已合并、未合并）：',
    name: 'branch_rule',
    choices: ['branch_all', 'branch_merged', 'branch_no_merged'],
    default: 'branch_merged',
  },
];

let answer = {};

function getParams() {
  return inquirer.prompt(question).then((res) => {
    answer = { ...res };
  });
}

function confirmAgain() {
  return inquirer
    .prompt([
      {
        type: 'list',
        message: `
将会删除【${format[answer.date_range]}】、【${
          format[answer.branch_rule]
        }】的远端分支，条件是分支名包含【'${answer.include_filters}'】且不包含【'${
          answer.excluded_filters
        }'】。确定执行？`,
        name: 'answer',
        choices: ['yes', 'no'],
        default: 'yes',
      },
    ])
    .then((res) => {
      if (res.answer === 'yes') {
        let paramsArr = Object.values(answer);
        console.log(
          `参数获取完毕，开始执行删除脚本: delBranch.sh ${paramsArr.map((v) => `'${v}'`).join(' ')}
          `,
        );
        const childProcess = spawn('sh', [path.resolve(__dirname, `./delBranch.sh`), ...paramsArr]);
        childProcess.stdout.on('data', (data) => {
          console.log(`${data}`);
        });
        childProcess.stderr.on('data', (data) => {
          console.error(`e：${data}`);
        });
      } else {
        console.log('终止执行');
      }
    });
}

async function main() {
  console.log(`请选择清理远端分支规则（master、main、release、develop分支不受影响）：
`);
  await getParams();
  await confirmAgain();
}
