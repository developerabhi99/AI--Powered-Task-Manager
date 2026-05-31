import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';

export const db = new PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
    { emit: 'event', level: 'info' },
    { emit: 'event', level: 'warn' },
    { emit: 'event', level: 'error' },
  ],
});

db.$on('query', (e) => {
  logger.debug(`Query: ${e.query} - Params: ${e.params} - Duration: ${e.duration}ms`);
});

db.$on('info', (e) => {
  logger.info(e.message);
});

db.$on('warn', (e) => {
  logger.warn(e.message);
});

db.$on('error', (e) => {
  logger.error(e.message);
});
