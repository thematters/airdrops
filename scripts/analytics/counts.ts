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
  let totalAddressesbyCategory: { [key: string]: number } = {}
  sources.forEach((src: string) => {
    const srcPath: string = path.join(sourcesPath, src)
    const srcData = readJSONFile(srcPath)
    totalAddressesbyCategory[srcData.category] = Object.keys(srcData.airdrop).length
  })

  // count total addresses
  const totalAddresses = Object.keys(totalAddressesbyCategory).reduce(
    (acc, curr) => acc + totalAddressesbyCategory[curr],
    0
  )

  const totalUniqueAddresses = Object.keys(addressesData.addresses).length

  // count tokens by category
  const totalTokensByCategory: { [key: string]: number } = {}
  Object.keys(addressesData.addresses).forEach((address: string) => {
    const { proof, index, address: _a, total, ...categoriesTokens } = addressesData.addresses[address]

    const categoryTotal = Object.keys(categoriesTokens).reduce((acc, curr) => acc + categoriesTokens[curr], 0)
    if (categoryTotal !== total) {
      console.log('categoryTotal is not same as total', _a)
      return
    }

    Object.keys(categoriesTokens).forEach((category: string) => {
      if (totalTokensByCategory[category]) {
        totalTokensByCategory[category] += categoriesTokens[category]
      } else {
        totalTokensByCategory[category] = categoriesTokens[category]
      }
    })
  })

  // count total tokens
  let totalTokenAllocated = 0
  Object.keys(addressesData.addresses).forEach((address) => {
    totalTokenAllocated = totalTokenAllocated + addressesData.addresses[address].total
  })

  // outputs
  const outputPath = path.join(basePath, `analytics-counts.json`)
  rimraf.sync(outputPath)
  putJSONFile(outputPath, {
    totalAddresses,
    totalUniqueAddresses,
    totalTokenAllocated,
    totalTokensByCategory,
    totalAddressesbyCategory,
  })
})()
