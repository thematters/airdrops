import path from 'path'
import axios from 'axios'
import dotenv from 'dotenv'
import web3 from 'web3'

dotenv.config({
  path: path.join(__dirname, '../..', '.env.polygon-mumbai'),
})

export const getAssetTransfers = async (contract: string, fromBlock: number, nextPageKey?: string) => {
  const baseURL = `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`

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
          category: ['erc721'],
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

export const getAllAssetTransfers = async (contract: string, fromBlock: number) => {
  const transfers = []
  let nextPageKey: string | undefined
  let isLastPage = false

  while (!isLastPage) {
    const result = await getAssetTransfers(contract, fromBlock, nextPageKey)
    transfers.push(...result.transfers)
    nextPageKey = result.nextPageKey
    isLastPage = !nextPageKey
  }

  return transfers
}