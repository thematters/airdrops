import path from 'path' // Path routing
import { sum, Airdrop, Generator, readJSONFile, throwErrorAndExit } from './utils'

const args = process.argv.slice(2)

//
;(async () => {
  const inputPath = args[0]
  if (!inputPath) {
    throwErrorAndExit('Missing input path')
  }

  // Read config
  const configPath: string = path.join(__dirname, '..', inputPath, 'config.json')
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
    airdrops.push(srcData.airdrop)
  })
  const airdrop = sum(airdrops)

  // Initialize and call generator
  const outputPath: string = path.join(__dirname, '..', inputPath, 'merkle.json')
  const generator = new Generator(decimals, airdrop)
  await generator.process(outputPath)
})()
