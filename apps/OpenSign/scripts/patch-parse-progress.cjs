// Patches parse@8.x so file uploads with a progress callback survive a
// response without Content-Length (gzip from Railway's edge drops it).
//
// Upstream RESTController locks the body with getReader() *before* checking
// Content-Length, then falls back to response.json() on the locked stream:
// "Failed to execute 'json' on 'Response': body stream is locked". Every
// Parse.File.save({ progress }) — template upload, profile images — failed.
// Moving getReader() into the branch that uses it fixes all of them.
// Unfixed upstream through parse@8.7.0. Fails the build if the code drifts.
const fs = require('fs')
const path = require('path')

const file = path.join(__dirname, '..', 'node_modules', 'parse', 'lib', 'browser', 'RESTController.js')
const source = fs.readFileSync(file, 'utf8')
const MARKER = '/* playbook: getReader after length check */'

if (source.includes(MARKER)) {
  console.log('parse progress patch: already applied')
  process.exit(0)
}

const pattern = /const reader = response\.body\.getReader\(\);(\s*)const length = \+response\.headers\.get\('Content-Length'\) \|\| 0;(\s*)if \(length === 0\) \{([\s\S]*?)\} else \{/
const match = pattern.exec(source)
if (!match) {
  console.error(`parse progress patch: pattern not found in ${file}; check the parse version`)
  process.exit(1)
}
const [whole, gap1, gap2, emptyBranch] = match
const replacement = `const length = +response.headers.get('Content-Length') || 0;${gap2}if (length === 0) {${emptyBranch}} else {${gap1}${MARKER} const reader = response.body.getReader();`
fs.writeFileSync(file, source.replace(whole, replacement))
console.log('parse progress patch: applied')
