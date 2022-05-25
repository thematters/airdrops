# Airdops

A fork from [merkle-airdrop-starter](https://github.com/Anish-Agnihotri/merkle-airdrop-starter) and [merkle-distributor](https://github.com/Uniswap/merkle-distributor), but with snapshots!

## Setup

```bash
# Install dependencies
npm install
```

Install [Foundry](https://github.com/gakonst/foundry) for contract development and deployment.

## Take Snapshots

To take snapshots from POAPs and token contracts, please config `scripts/snapshots/config.json`.

```bash
# `./data/the-space-initial-airdrop` is the output directory
npm run snapshot -- ./data/the-space-initial-airdrop
```

### POAP

Distribute amount of tokens to POAP owners.

We use [POAP subgraph](https://thegraph.com/hosted-service/subgraph/poap-xyz/poap-xdai) of The Graph as the source.

**Note:** Limits on 1000 addresses, needs support for pagination.

```bash
npm run snapshot:poapOwners -- ./data/the-space-initial-airdrop
```

### Token Owners (ERC-721, ERC-20, ERC-1155)

Distribute amount of tokens to token owners.

#### For Owners of a Collection

We use [Alchemy Transfers API](https://docs.alchemy.com/alchemy/enhanced-apis/transfers-api) and [getNFTsForCollection](https://docs.alchemy.com/alchemy/enhanced-apis/nft-api/getnftsforcollection) as the source.

```bash
npm run snapshot:collectionOwners -- ./data/the-space-initial-airdrop
```

#### For Owners of a Token ID

We use [getOwnersForToken](https://docs.alchemy.com/alchemy/enhanced-apis/nft-api/getownersfortoken) as the source.

```bash
npm run snapshot:tokenOwners -- ./data/the-space-initial-airdrop
```

### Transfers

Distribute amount of tokens based on transfer count.

```bash
npm run snapshot:transfers -- ./data/the-space-initial-airdrop
```

## Generate Merkle Root

After snapshots are taken, we can generate merkle root (outputs to `data/the-space-initial-airdrop/merkle.json`).

**Note:** You can also put owner addresses (JSON file) to `data/the-space-initial-airdrop` folder as from different sources and update `data/the-space-initial-airdrop/config` manually.

```bash
# `./data/the-space-initial-airdrop` is the inputs (owner addresses) and outputs (proofs)
npm run generate:merkle -- ./data/the-space-initial-airdrop
```

## Deployment

Now we can update the merkle root to `.env.*` file, and deploy the contract to desired network.

```bash
cp .env.polygon-mumbai.example .env.polygon-mumbai

make deploy NETWORK=polygon-mumbai
```

## Test

```bash
cp .env.polygon-mumbai.example .env.polygon-mumbai

make test NETWORK=polygon-mumbai
```
