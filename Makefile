NETWORK ?= local # defaults to local node with ganache
include .env.$(NETWORK)

# Deps
update:; forge update

# Build & test
clean    :; forge clean
snapshot :; forge snapshot --gas-report
build: clean
	forge build
test:
	forge test --gas-report
trace: clean
	forge test -vvvvv --gas-report

# Deployments
deploy-airdrop: clean
	@forge create MerkleDistributor --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${AIRDROP_TOKEN_ADDRESS} --constructor-args ${AIRDROP_MERKLE_ROOT} --constructor-args ${AIRDROP_EXPIRED_AT} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

deploy-fairdrop: clean
	@forge create Fairdrop --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${AIRDROP_TOKEN_ADDRESS} --constructor-args ${FAIRDROP_OWNER_ADDRESS} --constructor-args ${FAIRDROP_SIGNER_ADDRESS} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

# Verifications
check-verification:
	@forge verify-check --chain-id ${CHAIN_ID} ${GUID} ${ETHERSCAN_API_KEY}
