import path from 'path' // Path routing
import { sum, Airdrop, Generator, readJSONFile, throwErrorAndExit } from './utils'

const args = process.argv.slice(2)

//
;(async () => {
  const inputPath = args[0]
  if (!inputPath) {
    throwErrorAndExit('Missing input path')
  }

  const basePath = path.join(__dirname, '..', inputPath)
  const configPath: string = path.join(basePath, 'config.json')
  const merkleOutputPath: string = path.join(basePath, 'merkle.json')
  const proofsOutputPath: string = path.join(basePath, 'proofs')

  // Read config
  const configData = readJSONFile(configPath)
  const decimals: number = configData.decimals ?? 18

  // Read sources
  if (configData['sources'] === undefined) {
    throwErrorAndExit('Missing "sources" param in config. Please add.')
  }

  let airdrops: Airdrop[] = []
  configData['sources'].forEach((src: string) => {
    const srcPath: string = path.join(__dirname, '..', inputPath, src)
    const srcData = readJSONFile(srcPath)
    airdrops.push(srcData)
  })
  const airdrop = sum(airdrops, proofsOutputPath)

  // Initialize and call generator
  const generator = new Generator(decimals, airdrop)
  await generator.process(merkleOutputPath, proofsOutputPath)
})()
