import { getAddress } from 'ethers/lib/utils'
import path from 'path'
import _ from 'lodash'

import {
  putJSONFile,
  readJSONFile,
  throwErrorAndExit,
  getAllAssetTransfers,
  getOwnersForCollection,
  logger,
} from '../utils'

type CollectionContract = { network: string; fromBlock: number; toBlock?: number; amount: number; cumulative?: boolean }

type Transfer = { from: string; to: string; erc721TokenId: string }

const args = process.argv.slice(2)

//
;(async () => {
  const ouputPath = args[0]
  if (!ouputPath) {
    throwErrorAndExit('Missing input path')
  }

  const basePath = path.join(__dirname, '../..', ouputPath)
  const sourcesPath = path.join(basePath, 'sources')
  const configPath: string = path.join(__dirname, 'config.json')

  // Read config
  const configData = readJSONFile(configPath)
  const collectionContracts: { [address: string]: CollectionContract } = configData.collectionOwners
  const keys = Object.keys(collectionContracts)

  // Scrape from Alchemy
  for (const key of keys) {
    const collectionContract = collectionContracts[key]

    const addresses: { [address: string]: number } = {}

    // use simple `getOwnersForCollection` if it's not cumulative
    if (!collectionContract.cumulative) {
      const owners = (await getOwnersForCollection({
        contract: key,
        network: collectionContract.network,
      })) as string[]

      // address to amount
      const amountPerToken = collectionContract.amount
      owners.forEach((address) => {
        const checksumAddress = getAddress(address)
        if (addresses[checksumAddress] && collectionContract.cumulative) {
          addresses[checksumAddress] += amountPerToken
        } else {
          addresses[checksumAddress] = amountPerToken
        }
      })
    }
    // use `getAllAssetTransfers` if it's cumulative
    else {
      const transfers = await getAllAssetTransfers({
        contract: key,
        network: collectionContract.network,
        fromBlock: collectionContract.fromBlock,
        toBlock: collectionContract.toBlock,
        category: ['erc721'],
      })

      // token to owner address
      const tokens: { [id: string]: string } = {}
      transfers.forEach((transfer: Transfer) => {
        tokens[transfer.erc721TokenId] = transfer.to
      })

      // address to amount
      const amountPerToken = collectionContract.amount
      Object.keys(tokens).forEach((id) => {
        const address = getAddress(tokens[id])
        if (addresses[address] && collectionContract.cumulative) {
          addresses[address] += amountPerToken
        } else {
          addresses[address] = amountPerToken
        }
      })
    }

    const data = {
      category: `collection-owners-${key}`,
      createdAt: new Date().toISOString(),
      airdrop: addresses,
    }

    logger.info(`Scrapped collection (${key}) owners: ${Object.keys(addresses).length}`)

    // outputs
    const outputPath = path.join(sourcesPath, `collection-owners-${key}.json`)
    putJSONFile(outputPath, data)
  }
})()
