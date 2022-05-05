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
deploy: clean
	@forge create MerkleDistributor --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${AIRDROP_TOKEN_ADDRESS} --constructor-args ${AIRDROP_MERKLE_ROOT} --constructor-args ${AIRDROP_EXPIRED_AT}

# Verifications
check-verification:
	@forge verify-check --chain-id ${CHAIN_ID} ${GUID} ${ETHERSCAN_API_KEY}

verify:
	@forge verify-contract --chain-id ${CHAIN_ID} --num-of-optimizations 200 --constructor-args ${ABI_ENCODE_CONSTRUCTOR_ARGS} --compiler-version v0.8.13+commit.abaa5c0e ${CONTRACT_ADDRESS} contracts/MerkleDistributor.sol:MerkleDistributor ${ETHERSCAN_API_KEY}
