const fs = require('fs')
const path = require('path')
const cwd = process.cwd()

if (process.argv.length < 2 + 2) {
  console.error('Provide paths to at least 2 files to merge together.')
  process.exit(110)
}

// // Make the paths relative. No need for unnecessary absolute paths
// function toRelative(coverage) {
//   const ret = {}
//   for (const entry of Object.values(coverage)) {
//     const relativized = path.relative(cwd, entry.path)
//     entry.path = relativized
//     ret[relativized] = entry
//   }
//   return ret  
// }

let acc = {}
process.argv.slice(2).forEach(c => acc = {...acc, ...JSON.parse(fs.readFileSync(c))})

console.log(JSON.stringify(acc))