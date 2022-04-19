import { getAddress } from 'ethers/lib/utils'
import path from 'path'
import _ from 'lodash'

import { putJSONFile, readJSONFile, throwErrorAndExit, getAllAssetTransfers, logger } from '../utils'

type TransferContract = { network: string; fromBlock: number; toBlock?: number; amounts: { [range: string]: number } }

type Transfer = { from: string; to: string }

const args = process.argv.slice(2)

//
;(async () => {
  const ouputPath = args[0]
  if (!ouputPath) {
    throwErrorAndExit('Missing input path')
  }

  const basePath = path.join(__dirname, '../..', ouputPath)
  const configPath: string = path.join(__dirname, 'config.json')

  // Read config
  const configData = readJSONFile(configPath)
  const transferContracts: { [address: string]: TransferContract } = configData.transfers
  const contracts = Object.keys(transferContracts)

  // Scrape from Alchemy
  for (const contract of contracts) {
    const transferContract = transferContracts[contract]
    const transfers = await getAllAssetTransfers({
      contract,
      network: transferContract.network,
      fromBlock: transferContract.fromBlock,
      toBlock: transferContract.toBlock,
    })

    // count transfers of addresses
    const addressTransfers: { [id: string]: number } = {}
    transfers.forEach((transfer: Transfer) => {
      const address = getAddress(transfer.to)

      if (address === '0x0000000000000000000000000000000000000000') {
        return
      }

      if (addressTransfers[address]) {
        addressTransfers[address] += 1
      } else {
        addressTransfers[address] = 1
      }
    })

    const getAmountInRange = (count: number) => {
      const ranges = Object.keys(transferContract.amounts)

      for (let i = 0; i < ranges.length; i++) {
        const range = ranges[i].split(':')
        const min = parseInt(range[0], 10)
        const max = parseInt(range[1], 10) || Infinity

        if (count > min && count <= max) {
          return transferContract.amounts[ranges[i]]
        }
      }

      return 0
    }

    // address to amount
    const addresses: { [id: string]: number } = {}
    Object.keys(addressTransfers).forEach((address) => {
      const transferCount = addressTransfers[address]
      const amount = getAmountInRange(transferCount)
      addresses[address] = amount
    })

    const data = {
      category: `transfer-${contract}`,
      createdAt: new Date().toISOString(),
      airdrop: addresses,
      transfers: addressTransfers,
    }

    logger.info(`Scrapped transfer (${contract}): ${Object.keys(addresses).length}`)

    // outputs
    const outputPath = path.join(basePath, `transfer-${contract}.json`)
    putJSONFile(outputPath, data)

    // update merkle config
    const merkleConfigPath = path.join(basePath, `config.json`)
    const merkleConfig = readJSONFile(merkleConfigPath)
    const sources = _.uniq([...merkleConfig.sources, `./transfer-${contract}.json`])
    putJSONFile(merkleConfigPath, { ...merkleConfig, sources })
  }
})()
