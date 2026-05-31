"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const helmet_1 = __importDefault(require("helmet"));
const cors_1 = __importDefault(require("cors"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const morgan_1 = __importDefault(require("morgan"));
const env_1 = require("./config/env");
const logger_1 = require("./utils/logger");
const errorHandler_1 = require("./middleware/errorHandler");
const taskRoutes_1 = __importDefault(require("./routes/taskRoutes"));
const categoryRoutes_1 = __importDefault(require("./routes/categoryRoutes"));
const categoryService_1 = require("./services/categoryService");
const db_1 = require("./services/db");
const app = (0, express_1.default)();
// 1. Security Headers
app.use((0, helmet_1.default)());
// 2. CORS configuration (allowing requests from Flutter Web or standard origins)
app.use((0, cors_1.default)({
    origin: '*', // For development, allow all. In production, we restrict this.
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
// 3. Rate Limiter to prevent abuse
const limiter = (0, express_rate_limit_1.default)({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // Limit each IP to 1000 requests per window
    standardHeaders: true,
    legacyHeaders: false,
    message: 'Too many requests from this IP, please try again after 15 minutes',
});
app.use('/api', limiter);
// 4. Request Logging (Morgan piped into Winston)
const morganFormat = env_1.env.NODE_ENV === 'development' ? 'dev' : 'combined';
app.use((0, morgan_1.default)(morganFormat, {
    stream: {
        write: (message) => logger_1.logger.info(message.trim()),
    },
}));
// 5. Body Parsers
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
// Health Check Route
app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});
// 6. API Route Registrations
app.use('/api/tasks', taskRoutes_1.default);
app.use('/api/categories', categoryRoutes_1.default);
// 7. Global 404 handler for unmatched routes
app.use((req, res) => {
    res.status(404).json({
        status: 'error',
        message: `Route ${req.method} ${req.originalUrl} not found`,
    });
});
// 8. Global Error Handler Middleware
app.use(errorHandler_1.errorHandler);
// Startup helper
const startServer = async () => {
    try {
        // Connect to database
        await db_1.db.$connect();
        logger_1.logger.info('🔌 Connected to PostgreSQL Database successfully');
        // Run database seeding
        await categoryService_1.CategoryService.seedDefaults();
        logger_1.logger.info('🌱 Database default categories seeded successfully');
        app.listen(env_1.env.PORT, () => {
            logger_1.logger.info(`🚀 Server running in ${env_1.env.NODE_ENV} mode on port ${env_1.env.PORT}`);
        });
    }
    catch (error) {
        logger_1.logger.error('Failed to start server:', error);
        process.exit(1);
    }
};
startServer();
// Graceful Shutdown
const handleShutdown = async (signal) => {
    logger_1.logger.info(`Received ${signal}. Shutting down gracefully...`);
    try {
        await db_1.db.$disconnect();
        logger_1.logger.info('Database disconnected. Exit successful.');
        process.exit(0);
    }
    catch (error) {
        logger_1.logger.error('Error during shutdown:', error);
        process.exit(1);
    }
};
process.on('SIGINT', () => handleShutdown('SIGINT'));
process.on('SIGTERM', () => handleShutdown('SIGTERM'));
process.on('unhandledRejection', (reason, promise) => {
    logger_1.logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
process.on('uncaughtException', (error) => {
    logger_1.logger.error('Uncaught Exception thrown:', error);
    // Optional: Graceful shutdown on uncaught exceptions
});
