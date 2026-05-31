"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.db = void 0;
const client_1 = require("@prisma/client");
const logger_1 = require("../utils/logger");
exports.db = new client_1.PrismaClient({
    log: [
        { emit: 'event', level: 'query' },
        { emit: 'event', level: 'info' },
        { emit: 'event', level: 'warn' },
        { emit: 'event', level: 'error' },
    ],
});
exports.db.$on('query', (e) => {
    logger_1.logger.debug(`Query: ${e.query} - Params: ${e.params} - Duration: ${e.duration}ms`);
});
exports.db.$on('info', (e) => {
    logger_1.logger.info(e.message);
});
exports.db.$on('warn', (e) => {
    logger_1.logger.warn(e.message);
});
exports.db.$on('error', (e) => {
    logger_1.logger.error(e.message);
});
