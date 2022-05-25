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

  // List addressess
  const proofsOutputPath: string = path.join(basePath, 'proofs')
  const addresses = fs.readdirSync(proofsOutputPath).filter((file) => file.includes('.json'))

  if (addresses.length <= 0) {
    throwErrorAndExit('Missing proofs.')
  }

  // Read addresses and token amount
  const addressesData: Array<any> = []
  addresses.forEach((address: string) => {
    const addressPath: string = path.join(proofsOutputPath, address)
    const addressData = readJSONFile(addressPath)
    const { proof, index, ...restData } = addressData

    addressesData.push({ address: address.split('.json')[0], ...restData })
  })

  // outputs
  const outputPath = path.join(basePath, `analytics-addresses.json`)
  rimraf.sync(outputPath)
  putJSONFile(outputPath, { addresses: addressesData.sort((a, b) => b.total - a.total) })
})()
