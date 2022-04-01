import fs from 'fs' // Filesystem
import { throwErrorAndExit } from './error'

export const readJSONFile = (p: string) => {
  if (!fs.existsSync(p)) {
    throwErrorAndExit('Missing config.json. Please add.')
  }

  const file: Buffer = fs.readFileSync(p)
  const data = JSON.parse(file.toString())

  return data
}
