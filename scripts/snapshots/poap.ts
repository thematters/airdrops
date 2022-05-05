import path from 'path'
import axios from 'axios'
import { getAddress } from 'ethers/lib/utils'
import _ from 'lodash'

import { logger, putJSONFile, readJSONFile, throwErrorAndExit } from '../utils'

const args = process.argv.slice(2)

const API_ENDPOINT = 'https://api.thegraph.com/subgraphs/name/poap-xyz/poap-xdai'

const makeQuery = (eventId: string) => `
  query {
    tokens(
      where: {
        event: "${eventId}"
        owner_not: "0x0000000000000000000000000000000000000000"
      }
      first: 1000
      skip: 0
    ) {
      owner {
        id
      }
    }
  }
`

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
  const events: { [eventId: string]: number } = configData.POAPs
  const eventIds = Object.keys(events)

  // Scrape from The Graph
  for (const eventId of eventIds) {
    const query = makeQuery(eventId)
    const response = await axios.post(API_ENDPOINT, { query })

    // address to amount
    const amountPerToken = events[eventId]
    const addresses: { [address: string]: number } = {}
    response.data.data.tokens.forEach((token: any) => {
      addresses[getAddress(token.owner.id)] = amountPerToken
    })

    const data = {
      category: `poap-${eventId}`,
      createdAt: new Date().toISOString(),
      airdrop: addresses,
    }

    logger.info(`Scrapped POAP (${eventId}) owners: ${Object.keys(addresses).length}`)

    // outputs
    const outputPath = path.join(basePath, `poap-${eventId}.json`)
    putJSONFile(outputPath, data)

    // update merkle config
    const merkleConfigPath = path.join(basePath, `config.json`)
    const merkleConfig = readJSONFile(merkleConfigPath)
    const sources = _.uniq([...merkleConfig.sources, `./poap-${eventId}.json`])
    putJSONFile(merkleConfigPath, { ...merkleConfig, sources })
  }
})()