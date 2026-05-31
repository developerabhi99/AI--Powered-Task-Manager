import { Request, Response, NextFunction } from 'express';
import { CategoryService } from '../services/categoryService';
import { z } from 'zod';

// Validation schemas
export const createCategorySchema = z.object({
  id: z.string().min(1, 'Category ID is required').max(50),
  name: z.string().min(1, 'Category Name is required').max(100),
  colorValue: z.number().int('Color value must be an integer'),
  iconCodePoint: z.number().int('Icon code point must be an integer'),
});

export class CategoryController {
  public static async getAll(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const categories = await CategoryService.getAll();
      res.status(200).json({
        status: 'success',
        data: { categories },
      });
    } catch (error) {
      next(error);
    }
  }

  public static async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await CategoryService.create(req.body);
      res.status(201).json({
        status: 'success',
        data: { category },
      });
    } catch (error) {
      next(error);
    }
  }

  public static async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const category = await CategoryService.delete(id);
      res.status(200).json({
        status: 'success',
        message: `Category "${category.name}" deleted successfully`,
      });
    } catch (error) {
      next(error);
    }
  }
}
