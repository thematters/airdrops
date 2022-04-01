export type Airdrop = Record<string, number>

// Count total airdrop token of address
export const sum = (airdrops: Airdrop[]): Airdrop => {
  const airdrop: Airdrop = {}

  airdrops.forEach((drop) => {
    const addresses = Object.keys(drop)

    addresses.forEach((address) => {
      if (airdrop[address]) {
        airdrop[address] = airdrop[address] + drop[address]
      } else {
        airdrop[address] = drop[address]
      }
    })
  })

  return airdrop
}
