import fs from 'fs' // Filesystem
import path from 'path'

import { throwErrorAndExit } from './error'

export const readJSONFile = (dst: string, ignore: boolean = false) => {
  if (!fs.existsSync(dst)) {
    if (ignore) {
      return {}
    }

    throwErrorAndExit(`Missing file: ${dst}`)
  }

  const file: Buffer = fs.readFileSync(dst)
  const data = JSON.parse(file.toString())

  return data
}

export const putJSONFile = (dst: string, data: { [key: string]: any }) => {
  const oldData = readJSONFile(dst, true)

  if (!fs.existsSync(dst) && !fs.existsSync(path.join(dst, `..`))) {
    fs.mkdirSync(path.join(dst, `..`))
  }

  fs.writeFileSync(dst, JSON.stringify({ ...oldData, ...data }, null, 2))

  return data
}
