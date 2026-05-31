"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CategoryController = exports.createCategorySchema = void 0;
const categoryService_1 = require("../services/categoryService");
const zod_1 = require("zod");
// Validation schemas
exports.createCategorySchema = zod_1.z.object({
    id: zod_1.z.string().min(1, 'Category ID is required').max(50),
    name: zod_1.z.string().min(1, 'Category Name is required').max(100),
    colorValue: zod_1.z.number().int('Color value must be an integer'),
    iconCodePoint: zod_1.z.number().int('Icon code point must be an integer'),
});
class CategoryController {
    static async getAll(_req, res, next) {
        try {
            const categories = await categoryService_1.CategoryService.getAll();
            res.status(200).json({
                status: 'success',
                data: { categories },
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async create(req, res, next) {
        try {
            const category = await categoryService_1.CategoryService.create(req.body);
            res.status(201).json({
                status: 'success',
                data: { category },
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async delete(req, res, next) {
        try {
            const { id } = req.params;
            const category = await categoryService_1.CategoryService.delete(id);
            res.status(200).json({
                status: 'success',
                message: `Category "${category.name}" deleted successfully`,
            });
        }
        catch (error) {
            next(error);
        }
    }
}
exports.CategoryController = CategoryController;
