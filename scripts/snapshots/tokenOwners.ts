import { getAddress } from 'ethers/lib/utils'
import path from 'path'
import _ from 'lodash'

import { putJSONFile, readJSONFile, throwErrorAndExit, getOwnersForToken, logger } from '../utils'

type TokenContract = { network: string; amount: number }

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
  const tokenContracts: { [address: string]: TokenContract } = configData.tokenOwners
  const keys = Object.keys(tokenContracts)

  // Scrape from Alchemy
  for (const key of keys) {
    const tokenContract = tokenContracts[key]
    const [contract, tokenId] = key.split(':')

    const owners = (await getOwnersForToken({
      contract,
      tokenId,
      network: tokenContract.network,
    })) as string[]

    // address to amount
    const addresses: { [address: string]: number } = {}
    owners.forEach((address) => {
      const validAddress = getAddress(address)
      addresses[validAddress] = tokenContract.amount
    })

    const data = {
      category: `token-owners-${key}`,
      createdAt: new Date().toISOString(),
      airdrop: addresses,
    }

    logger.info(`Scrapped token id (${key}) owners: ${Object.keys(addresses).length}`)

    // outputs
    const outputPath = path.join(basePath, `token-owners-${key}.json`)
    putJSONFile(outputPath, data)

    // update merkle config
    const merkleConfigPath = path.join(basePath, `config.json`)
    const merkleConfig = readJSONFile(merkleConfigPath)
    const sources = _.uniq([...merkleConfig.sources, `./token-owners-${key}.json`])
    putJSONFile(merkleConfigPath, { ...merkleConfig, sources })
  }
})()
