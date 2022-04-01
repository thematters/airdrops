import { logger } from './logger' // Logging

/**
 * Throws error and exists process
 * @param {string} erorr to log
 */
export const throwErrorAndExit = (error: string): void => {
  logger.error(error)
  process.exit(1)
}
