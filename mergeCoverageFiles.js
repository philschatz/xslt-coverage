const fs = require('fs')
if (process.argv.length < 2 + 2) {
  console.error('Provide paths to at least 2 files to merge together.')
  process.exit(110)
}
let acc = {}
process.argv.slice(2).forEach(c => acc = {...acc, ...JSON.parse(fs.readFileSync(c))})
console.log(JSON.stringify(acc, null, 2))