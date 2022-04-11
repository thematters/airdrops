# Airdops

A fork from [merkle-airdrop-starter](https://github.com/Anish-Agnihotri/merkle-airdrop-starter) and [merkle-distributor](https://github.com/Uniswap/merkle-distributor).

## Setup

```bash
# Install dependencies
npm install

# Scrape address list
npm run scrape:poap -- ./data/alice

# Generate Merkle Root
npm run generate:merkle -- ./data/alice
```

## Test

```bash
cp .env.polygon-mumbai.example .env.polygon-mumbai

make test NETWORK=polygon-mumbai
```

## Deployment

```bash
make deploy NETWORK=polygon-mumbai
```
