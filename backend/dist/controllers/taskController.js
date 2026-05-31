"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaskController = exports.updateTaskSchema = exports.createTaskSchema = void 0;
const taskService_1 = require("../services/taskService");
const zod_1 = require("zod");
// Zod Validation Schemas
exports.createTaskSchema = zod_1.z.object({
    id: zod_1.z.string().optional(),
    title: zod_1.z.string().min(1, 'Task title is required').max(200),
    description: zod_1.z.string().optional().default(''),
    dueDate: zod_1.z.string().datetime({ message: 'Due date must be a valid ISO 8601 datetime string' }).transform((val) => new Date(val)),
    priority: zod_1.z.enum(['low', 'medium', 'high']).default('medium'),
    categoryId: zod_1.z.string().min(1, 'Category ID is required'),
    duration: zod_1.z.number().int().nonnegative().optional().default(0),
    subtasks: zod_1.z
        .array(zod_1.z.object({
        title: zod_1.z.string().min(1, 'Subtask title is required'),
        isCompleted: zod_1.z.boolean().optional().default(false),
    }))
        .optional(),
});
exports.updateTaskSchema = zod_1.z.object({
    title: zod_1.z.string().min(1, 'Task title cannot be empty').max(200).optional(),
    description: zod_1.z.string().optional(),
    dueDate: zod_1.z.string().datetime({ message: 'Due date must be a valid ISO 8601 datetime string' }).transform((val) => new Date(val)).optional(),
    priority: zod_1.z.enum(['low', 'medium', 'high']).optional(),
    isCompleted: zod_1.z.boolean().optional(),
    categoryId: zod_1.z.string().min(1).optional(),
    duration: zod_1.z.number().int().nonnegative().optional(),
    subtasks: zod_1.z
        .array(zod_1.z.object({
        id: zod_1.z.string().optional(),
        title: zod_1.z.string().min(1, 'Subtask title is required'),
        isCompleted: zod_1.z.boolean(),
    }))
        .optional(),
});
class TaskController {
    static async getAll(req, res, next) {
        try {
            const { categoryId, isCompleted, search } = req.query;
            // Parse status filter if provided
            let statusFilter = undefined;
            if (isCompleted === 'true') {
                statusFilter = true;
            }
            else if (isCompleted === 'false') {
                statusFilter = false;
            }
            const tasks = await taskService_1.TaskService.getAll({
                categoryId: categoryId,
                isCompleted: statusFilter,
                search: search,
            });
            res.status(200).json({
                status: 'success',
                results: tasks.length,
                data: { tasks },
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async getById(req, res, next) {
        try {
            const { id } = req.params;
            const task = await taskService_1.TaskService.getById(id);
            res.status(200).json({
                status: 'success',
                data: { task },
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async create(req, res, next) {
        try {
            const task = await taskService_1.TaskService.create(req.body);
            res.status(201).json({
                status: 'success',
                data: { task },
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async update(req, res, next) {
        try {
            const { id } = req.params;
            const task = await taskService_1.TaskService.update(id, req.body);
            res.status(200).json({
                status: 'success',
                data: { task },
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async delete(req, res, next) {
        try {
            const { id } = req.params;
            await taskService_1.TaskService.delete(id);
            res.status(200).json({
                status: 'success',
                message: 'Task deleted successfully',
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async toggleTask(req, res, next) {
        try {
            const { id } = req.params;
            const task = await taskService_1.TaskService.toggleTaskCompletion(id);
            res.status(200).json({
                status: 'success',
                data: { task },
            });
        }
        catch (error) {
            next(error);
        }
    }
    static async toggleSubtask(req, res, next) {
        try {
            const { id, subtaskId } = req.params;
            const task = await taskService_1.TaskService.toggleSubtaskCompletion(id, subtaskId);
            res.status(200).json({
                status: 'success',
                data: { task },
            });
        }
        catch (error) {
            next(error);
        }
    }
}
exports.TaskController = TaskController;
