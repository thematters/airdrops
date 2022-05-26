import path from 'path'
import { getAddress, parseUnits, solidityKeccak256 } from 'ethers/lib/utils' // Ethers utils

import { putJSONFile } from '../utils/file'

export type AirdropItem = Record<string, number>

export type Airdrop = {
  category: string
  airdrop: Record<string, number>
}

// Count total airdrop token of address
export const sum = (airdrops: Airdrop[], proofsOutputPath: string): AirdropItem => {
  const airdrop: AirdropItem = {}

  airdrops.forEach((drop) => {
    const addresses = Object.keys(drop.airdrop)

    addresses.forEach((address) => {
      const checksumAddress = getAddress(address)
      const amount = drop.airdrop[address]

      if (airdrop[checksumAddress]) {
        airdrop[checksumAddress] = airdrop[checksumAddress] + amount
      } else {
        airdrop[checksumAddress] = amount
      }

      const addressPath = path.join(proofsOutputPath, `${address.toLocaleLowerCase()}.json`)
      putJSONFile(addressPath, { [drop.category]: amount })
    })
  })

  return airdrop
}
