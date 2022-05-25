import path from 'path'
import fs from 'fs'
import rimraf from 'rimraf'

import { Generator } from './generator'
import { sum, Airdrop } from './sum'
import { readJSONFile, throwErrorAndExit } from '../utils'

const args = process.argv.slice(2)

//
;(async () => {
  const inputPath = args[0]
  if (!inputPath) {
    throwErrorAndExit('Missing input path')
  }

  const basePath = path.join(__dirname, '../..', inputPath)
  const configPath: string = path.join(basePath, 'config.json')
  const merkleOutputPath: string = path.join(basePath, 'merkle.json')
  const proofsOutputPath: string = path.join(basePath, 'proofs')

  // Read config
  const configData = readJSONFile(configPath)
  const decimals: number = configData.decimals ?? 18

  // Remove proofs dir
  rimraf.sync(proofsOutputPath)

  // Read sources
  const sourcesPath = path.join(__dirname, '../..', inputPath, 'sources')
  const sources = fs.readdirSync(sourcesPath).filter((file) => file.includes('.json'))

  if (sources.length <= 0) {
    throwErrorAndExit('Missing sources.')
  }

  let airdrops: Airdrop[] = []
  sources.forEach((src: string) => {
    const srcPath: string = path.join(sourcesPath, src)
    const srcData = readJSONFile(srcPath)
    airdrops.push(srcData)
  })
  const airdrop = sum(airdrops, proofsOutputPath)

  // Initialize and call generator
  const generator = new Generator(decimals, airdrop)
  await generator.process(merkleOutputPath, proofsOutputPath)
})()
