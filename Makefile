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
	@forge create TheSpaceAirdrop --rpc-url ${ETH_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --constructor-args ${TOKEN_ADDRESS} --constructor-args ${MERKLE_ROOT} --constructor-args ${EXPIRED_AT}

# Verifications
check-verification:
	@forge verify-check --chain-id ${CHAIN_ID} ${GUID} ${ETHERSCAN_API_KEY}

verify:
	@forge verify-contract --chain-id ${CHAIN_ID} --constructor-args ${ABI_ENCODE_CONSTRUCTOR_ARGS} --num-of-optimizations 200 --compiler-version v0.8.13+commit.abaa5c0e ${CONTRACT_ADDRESS} ${ETHERSCAN_API_KEY}
