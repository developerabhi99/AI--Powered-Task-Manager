"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateRequest = void 0;
const zod_1 = require("zod");
const errors_1 = require("../utils/errors");
const validateRequest = (schema) => {
    return async (req, _res, next) => {
        try {
            if (schema.body) {
                req.body = await schema.body.parseAsync(req.body);
            }
            if (schema.query) {
                req.query = await schema.query.parseAsync(req.query);
            }
            if (schema.params) {
                req.params = await schema.params.parseAsync(req.params);
            }
            next();
        }
        catch (error) {
            if (error instanceof zod_1.ZodError) {
                const errorRecord = {};
                error.errors.forEach((err) => {
                    const path = err.path.join('.');
                    if (!errorRecord[path]) {
                        errorRecord[path] = [];
                    }
                    errorRecord[path].push(err.message);
                });
                next(new errors_1.ValidationError('Request validation failed', errorRecord));
            }
            else {
                next(error);
            }
        }
    };
};
exports.validateRequest = validateRequest;
