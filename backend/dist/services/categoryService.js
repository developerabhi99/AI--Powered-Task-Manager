"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CategoryService = void 0;
const db_1 = require("./db");
const errors_1 = require("../utils/errors");
class CategoryService {
    static mapCategory(cat) {
        return {
            ...cat,
            colorValue: Number(cat.colorValue),
        };
    }
    static async getAll() {
        const categories = await db_1.db.category.findMany({
            orderBy: { name: 'asc' },
        });
        return categories.map(this.mapCategory);
    }
    static async getById(id) {
        const category = await db_1.db.category.findUnique({
            where: { id },
        });
        if (!category) {
            throw new errors_1.NotFoundError(`Category with ID "${id}" not found`);
        }
        return this.mapCategory(category);
    }
    static async create(data) {
        const existing = await db_1.db.category.findUnique({
            where: { id: data.id },
        });
        if (existing) {
            throw new errors_1.ConflictError(`Category with ID "${data.id}" already exists`);
        }
        const category = await db_1.db.category.create({
            data: {
                id: data.id,
                name: data.name,
                colorValue: data.colorValue.toString(),
                iconCodePoint: data.iconCodePoint,
            },
        });
        return this.mapCategory(category);
    }
    static async delete(id) {
        // Check if category exists
        await this.getById(id);
        // Check if category has tasks
        const taskCount = await db_1.db.task.count({
            where: { categoryId: id },
        });
        if (taskCount > 0) {
            throw new errors_1.ConflictError(`Cannot delete category "${id}" because it is associated with ${taskCount} task(s)`);
        }
        const deleted = await db_1.db.category.delete({
            where: { id },
        });
        return this.mapCategory(deleted);
    }
    // Seeds default categories if they are missing
    static async seedDefaults() {
        const defaults = [
            { id: 'work', name: 'Work', colorValue: 0xFF70A1FF, iconCodePoint: 0xe1b1 },
            { id: 'personal', name: 'Personal', colorValue: 0xFF9B5DE5, iconCodePoint: 0xe491 },
            { id: 'shopping', name: 'Shopping', colorValue: 0xFFF15BB5, iconCodePoint: 0xe59c },
            { id: 'health', name: 'Health', colorValue: 0xFF05C46B, iconCodePoint: 0xe243 },
            { id: 'study', name: 'Study', colorValue: 0xFFFF9F43, iconCodePoint: 0xe5b7 },
        ];
        for (const cat of defaults) {
            await db_1.db.category.upsert({
                where: { id: cat.id },
                update: {},
                create: {
                    id: cat.id,
                    name: cat.name,
                    colorValue: cat.colorValue.toString(),
                    iconCodePoint: cat.iconCodePoint,
                },
            });
        }
    }
}
exports.CategoryService = CategoryService;
