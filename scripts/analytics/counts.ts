import path from 'path'
import fs from 'fs'
import rimraf from 'rimraf'

import { putJSONFile, readJSONFile, throwErrorAndExit } from '../utils'

const args = process.argv.slice(2)

//
;(async () => {
  const inputPath = args[0]
  if (!inputPath) {
    throwErrorAndExit('Missing input path')
  }

  const basePath = path.join(__dirname, '../..', inputPath)

  // Read sources
  const sourcesPath = path.join(__dirname, '../..', inputPath, 'sources')
  const sources = fs.readdirSync(sourcesPath).filter((file) => file.includes('.json'))

  if (sources.length <= 0) {
    throwErrorAndExit('Missing sources.')
  }

  // Read `anayltics-addresses.json`
  const addressesPath = path.join(__dirname, '../..', inputPath, 'analytics-addresses.json')
  const addressesData = readJSONFile(addressesPath)

  // count addresses by source
  let categories: { [key: string]: number } = {}
  sources.forEach((src: string) => {
    const srcPath: string = path.join(sourcesPath, src)
    const srcData = readJSONFile(srcPath)
    categories[srcData.category] = Object.keys(srcData.airdrop).length
  })

  // count total addresses
  const totalAddresses = Object.keys(categories).reduce((acc, curr) => acc + categories[curr], 0)

  const totalUniqueAddresses = Object.keys(addressesData.addresses).length

  // count total tokens
  const totalTokenAllocated = Object.keys(addressesData.addresses).reduce(
    (acc, curr) => acc + addressesData.addresses[curr].total,
    0
  )

  // outputs
  const outputPath = path.join(basePath, `analytics-counts.json`)
  rimraf.sync(outputPath)
  putJSONFile(outputPath, {
    totalAddresses,
    totalUniqueAddresses,
    totalTokenAllocated,
    categories,
  })
})()
