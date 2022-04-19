import { getAddress } from 'ethers/lib/utils'
import path from 'path'
import _ from 'lodash'

import { putJSONFile, readJSONFile, throwErrorAndExit, getAllAssetTransfers, logger } from '../utils'

type TokenContract = { network: string; fromBlock: number; toBlock?: number; amount: number; cumulative?: boolean }

type Transfer = { from: string; to: string; erc721TokenId: string }

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
  const tokenContracts: { [address: string]: TokenContract } = configData.tokens
  const contracts = Object.keys(tokenContracts)

  // Scrape from Alchemy
  for (const contract of contracts) {
    const tokenContract = tokenContracts[contract]
    const transfers = await getAllAssetTransfers({
      contract,
      network: tokenContract.network,
      fromBlock: tokenContract.fromBlock,
      toBlock: tokenContract.toBlock,
      category: ['erc721'],
    })

    // token to owner address
    const tokens: { [id: string]: string } = {}
    transfers.forEach((transfer: Transfer) => {
      tokens[transfer.erc721TokenId] = transfer.to
    })

    // address to amount
    const amountPerToken = tokenContract.amount
    const addresses: { [address: string]: number } = {}
    Object.keys(tokens).forEach((id) => {
      const address = getAddress(tokens[id])
      if (addresses[address] && tokenContract.cumulative) {
        addresses[address] += amountPerToken
      } else {
        addresses[address] = amountPerToken
      }
    })

    const data = {
      category: `token-${contract}`,
      createdAt: new Date().toISOString(),
      airdrop: addresses,
    }

    logger.info(`Scrapped Token (${contract}) owners: ${Object.keys(addresses).length}`)

    // outputs
    const outputPath = path.join(basePath, `token-${contract}.json`)
    putJSONFile(outputPath, data)

    // update merkle config
    const merkleConfigPath = path.join(basePath, `config.json`)
    const merkleConfig = readJSONFile(merkleConfigPath)
    const sources = _.uniq([...merkleConfig.sources, `./token-${contract}.json`])
    putJSONFile(merkleConfigPath, { ...merkleConfig, sources })
  }
})()
