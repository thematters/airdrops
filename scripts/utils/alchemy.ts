import path from 'path'
import axios from 'axios'
import dotenv from 'dotenv'
import web3 from 'web3'

type AssetTransferParams = {
  contract: string
  network: string
  fromBlock: number
  toBlock?: number | null
  nextPageKey?: string
  category?: Array<'external' | 'internal' | 'token' | 'erc20' | 'erc721' | 'erc1155'>
}

dotenv.config({
  path: path.join(__dirname, '../..', '.env.polygon-mumbai'),
})

export const getAssetTransfers = async ({
  contract,
  network,
  fromBlock,
  toBlock,
  nextPageKey,
  category,
}: AssetTransferParams) => {
  const apiKey = process.env.ALCHEMY_API_KEY
  const baseURL = {
    mainnet: `https://eth-mainnet.alchemyapi.io/v2/${apiKey}`,
    polygon: `https://polygon-mainnet.g.alchemy.com/v2/${apiKey}`,
    mumbai: `https://polygon-mumbai.g.alchemy.com/v2/${apiKey}`,
  }[network]

  console.log(`Retrieving ${contract} transfers from ${network}`, { nextPageKey })

  const response = await axios({
    method: 'post',
    url: `${baseURL}`,
    headers: { 'Content-Type': 'application/json' },
    data: JSON.stringify({
      jsonrpc: '2.0',
      id: 0,
      method: 'alchemy_getAssetTransfers',
      params: [
        {
          contractAddresses: [contract],
          fromBlock: web3.utils.numberToHex(fromBlock),
          toBlock: toBlock || undefined,
          category: category || ['erc721'],
          excludeZeroValue: false,
          // maxCount: web3.utils.numberToHex(1000),
          pageKey: nextPageKey,
        },
      ],
    }),
  })

  const result = response.data.result

  return {
    transfers: result.transfers,
    nextPageKey: result.pageKey,
  }
}

export const getAllAssetTransfers = async (params: AssetTransferParams) => {
  const transfers = []
  let nextPageKey: string | undefined
  let isLastPage = false

  while (!isLastPage) {
    const result = await getAssetTransfers({ ...params, nextPageKey })
    transfers.push(...result.transfers)
    nextPageKey = result.nextPageKey
    isLastPage = !nextPageKey
  }

  return transfers
}
