import fs from 'fs' // Filesystem
import keccak256 from 'keccak256' // Keccak256 hashing
import MerkleTree from 'merkletreejs' // MerkleTree.js
import { logger } from './logger' // Logging
import { getAddress, parseUnits, solidityKeccak256 } from 'ethers/lib/utils' // Ethers utils
import { putJSONFile } from './file'
import path from 'path'

// Airdrop recipient addresses and scaled token values
type AirdropRecipient = {
  // Recipient address
  address: string
  // Scaled-to-decimals token value
  value: string
  // Amount
  amount: number
  // Index
  index?: number
  // Proof
  proof?: string[]
}

export class Generator {
  // Airdrop recipients
  recipients: AirdropRecipient[] = []

  /**
   * Setup generator
   * @param {number} decimals of token
   * @param {Record<string, number>} airdrop address to token claim mapping
   */
  constructor(decimals: number, airdrop: Record<string, number>) {
    // For each airdrop entry
    for (const [address, tokens] of Object.entries(airdrop)) {
      // Push:
      this.recipients.push({
        // Checksum address
        address: getAddress(address),
        // Scaled number of tokens claimable by recipient
        value: parseUnits(tokens.toString(), decimals).toString(),
        // Amount
        amount: tokens,
      })
    }
  }

  /**
   * Generate Merkle Tree leaf from address and value
   * @param {string} address of airdrop claimee
   * @param {string} value of airdrop tokens to claimee
   * @returns {Buffer} Merkle Tree node
   */
  generateLeaf(address: string, value: string): Buffer {
    return Buffer.from(
      // Hash in appropriate Merkle format
      solidityKeccak256(['address', 'uint256'], [address, value]).slice(2),
      'hex'
    )
  }

  async process(merkleOutputPath: string, proofsOutputPath: string): Promise<void> {
    logger.info('Generating Merkle tree.')

    // Generate merkle tree
    const merkleTree = new MerkleTree(
      // Generate leafs
      this.recipients.map(({ address, value }) => this.generateLeaf(address, value)),
      // Hashing function
      keccak256,
      { sortPairs: true }
    )

    // Collect and log merkle root
    const merkleRoot: string = merkleTree.getHexRoot()
    logger.info(`Generated Merkle root: ${merkleRoot}`)

    // Collect proofs of leaves
    const proofs = [...this.recipients]
    proofs.forEach((recipient, index) => {
      const leaf = this.generateLeaf(recipient.address, recipient.value)
      const proof = merkleTree.getHexProof(leaf, index)
      proofs[index].index = index
      proofs[index].proof = proof

      // Save proof
      const addressPath = path.join(proofsOutputPath, `${recipient.address}.json`)
      putJSONFile(addressPath, { proof, index, total: recipient.amount })
    })

    // Collect and save merkle tree + root
    fs.writeFileSync(
      // Output to merkle.json
      merkleOutputPath,
      // Root + full tree
      JSON.stringify(
        {
          root: merkleRoot,
          // proofs,
        },
        null,
        2
      )
    )
    logger.info('Generated merkle tree and root saved to Merkle.json.')
  }
}
