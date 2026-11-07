// Fails when the Arabic and English dictionaries drift apart.
// Usage: npm run check:i18n
import { readFileSync } from 'node:fs'

const source = readFileSync(new URL('../src/stores/locale.ts', import.meta.url), 'utf8')
const start = source.indexOf('const translations = ') + 'const translations = '.length
let depth = 0
let quote = null
let end = start
for (; end < source.length; end += 1) {
  const char = source[end]
  if (quote) {
    if (char === '\\') end += 1
    else if (char === quote) quote = null
  } else if (char === "'" || char === '"' || char === '`') quote = char
  else if (char === '{') depth += 1
  else if (char === '}' && --depth === 0) break
}
const translations = new Function(`return (${source.slice(start, end + 1)})`)()

const flat = (object, prefix = '') => Object.entries(object).flatMap(([key, value]) =>
  value && typeof value === 'object' ? flat(value, `${prefix}${key}.`) : [`${prefix}${key}`])
const pick = (object, path) => path.split('.').reduce((node, key) => node[key], object)
const arabic = /[\u0600-\u06FF]/

const ar = new Set(flat(translations.ar))
const en = new Set(flat(translations.en))
const problems = [
  ...[...ar].filter((key) => !en.has(key)).map((key) => `missing in EN: ${key}`),
  ...[...en].filter((key) => !ar.has(key)).map((key) => `missing in AR: ${key}`),
  ...[...en].filter((key) => arabic.test(pick(translations.en, key))).map((key) => `Arabic text inside EN value: ${key}`),
]

if (problems.length) {
  console.error(problems.join('\n'))
  process.exit(1)
}
console.log(`i18n OK — ${ar.size} keys in both languages`)
