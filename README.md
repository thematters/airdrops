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

### POAP

We use [POAP subgraph](https://thegraph.com/hosted-service/subgraph/poap-xyz/poap-xdai) of The Graph as the source.

**Note:** Limits on 1000 addresses, needs support for pagination.

```bash
# `./data/space` is the output directory
npm run snapshot:poap -- ./data/space
```

### Tokens (ERC-721, ERC-20, ERC-1155)

We use [Alchemy Transfers API](https://docs.alchemy.com/alchemy/enhanced-apis/transfers-api) as the source.

```bash
# `./data/space` is the output directory
npm run snapshot:tokens -- ./data/space
```

## Generate Merkle Root

After snapshots are taken, we can generate merkle root (outputs to `data/space/merkle.json`).

**Note:** You can also put owner addresses (JSON file) to `data/space` folder as from different sources and update `data/space/config` manually.

```bash
# `./data/space` is the inputs (owner addresses) and outputs (proofs)
npm run generate:merkle -- ./data/space
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
