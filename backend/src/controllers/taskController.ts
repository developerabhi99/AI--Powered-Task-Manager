import { Request, Response, NextFunction } from 'express';
import { TaskService } from '../services/taskService';
import { z } from 'zod';

// Zod Validation Schemas
export const createTaskSchema = z.object({
  id: z.string().optional(),
  title: z.string().min(1, 'Task title is required').max(200),
  description: z.string().optional().default(''),
  dueDate: z.string().datetime({ message: 'Due date must be a valid ISO 8601 datetime string' }).transform((val) => new Date(val)),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  categoryId: z.string().min(1, 'Category ID is required'),
  duration: z.number().int().nonnegative().optional().default(0),
  reminderMinutes: z.number().int().min(-1).optional().default(-1),
  subtasks: z
    .array(
      z.object({
        title: z.string().min(1, 'Subtask title is required'),
        isCompleted: z.boolean().optional().default(false),
      })
    )
    .optional(),
});

export const updateTaskSchema = z.object({
  title: z.string().min(1, 'Task title cannot be empty').max(200).optional(),
  description: z.string().optional(),
  dueDate: z.string().datetime({ message: 'Due date must be a valid ISO 8601 datetime string' }).transform((val) => new Date(val)).optional(),
  priority: z.enum(['low', 'medium', 'high']).optional(),
  isCompleted: z.boolean().optional(),
  categoryId: z.string().min(1).optional(),
  duration: z.number().int().nonnegative().optional(),
  reminderMinutes: z.number().int().min(-1).optional(),
  subtasks: z
    .array(
      z.object({
        id: z.string().optional(),
        title: z.string().min(1, 'Subtask title is required'),
        isCompleted: z.boolean(),
      })
    )
    .optional(),
});

export class TaskController {
  public static async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { categoryId, isCompleted, search } = req.query;

      // Parse status filter if provided
      let statusFilter: boolean | undefined = undefined;
      if (isCompleted === 'true') {
        statusFilter = true;
      } else if (isCompleted === 'false') {
        statusFilter = false;
      }

      const tasks = await TaskService.getAll({
        categoryId: categoryId as string,
        isCompleted: statusFilter,
        search: search as string,
      });

      res.status(200).json({
        status: 'success',
        results: tasks.length,
        data: { tasks },
      });
    } catch (error) {
      next(error);
    }
  }

  public static async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const task = await TaskService.getById(id);
      
      res.status(200).json({
        status: 'success',
        data: { task },
      });
    } catch (error) {
      next(error);
    }
  }

  public static async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const task = await TaskService.create(req.body);
      res.status(201).json({
        status: 'success',
        data: { task },
      });
    } catch (error) {
      next(error);
    }
  }

  public static async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const task = await TaskService.update(id, req.body);
      res.status(200).json({
        status: 'success',
        data: { task },
      });
    } catch (error) {
      next(error);
    }
  }

  public static async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      await TaskService.delete(id);
      res.status(200).json({
        status: 'success',
        message: 'Task deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  public static async toggleTask(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const task = await TaskService.toggleTaskCompletion(id);
      res.status(200).json({
        status: 'success',
        data: { task },
      });
    } catch (error) {
      next(error);
    }
  }

  public static async toggleSubtask(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id, subtaskId } = req.params;
      const task = await TaskService.toggleSubtaskCompletion(id, subtaskId);
      res.status(200).json({
        status: 'success',
        data: { task },
      });
    } catch (error) {
      next(error);
    }
  }
}
