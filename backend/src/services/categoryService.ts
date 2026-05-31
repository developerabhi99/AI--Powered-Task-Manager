import { db } from './db';
import { ConflictError, NotFoundError } from '../utils/errors';
import { Category } from '@prisma/client';

export interface CategoryWithIntColor {
  id: string;
  name: string;
  colorValue: number;
  iconCodePoint: number;
  createdAt: Date;
  updatedAt: Date;
}

export class CategoryService {
  private static mapCategory(cat: Category): CategoryWithIntColor {
    return {
      ...cat,
      colorValue: Number(cat.colorValue),
    };
  }

  public static async getAll(): Promise<CategoryWithIntColor[]> {
    const categories = await db.category.findMany({
      orderBy: { name: 'asc' },
    });
    return categories.map(this.mapCategory);
  }

  public static async getById(id: string): Promise<CategoryWithIntColor> {
    const category = await db.category.findUnique({
      where: { id },
    });

    if (!category) {
      throw new NotFoundError(`Category with ID "${id}" not found`);
    }

    return this.mapCategory(category);
  }

  public static async create(data: {
    id: string;
    name: string;
    colorValue: number;
    iconCodePoint: number;
  }): Promise<CategoryWithIntColor> {
    const existing = await db.category.findUnique({
      where: { id: data.id },
    });

    if (existing) {
      throw new ConflictError(`Category with ID "${data.id}" already exists`);
    }

    const category = await db.category.create({
      data: {
        id: data.id,
        name: data.name,
        colorValue: data.colorValue.toString(),
        iconCodePoint: data.iconCodePoint,
      },
    });

    return this.mapCategory(category);
  }

  public static async delete(id: string): Promise<CategoryWithIntColor> {
    // Check if category exists
    await this.getById(id);

    // Check if category has tasks
    const taskCount = await db.task.count({
      where: { categoryId: id },
    });

    if (taskCount > 0) {
      throw new ConflictError(
        `Cannot delete category "${id}" because it is associated with ${taskCount} task(s)`
      );
    }

    const deleted = await db.category.delete({
      where: { id },
    });

    return this.mapCategory(deleted);
  }

  // Seeds default categories if they are missing
  public static async seedDefaults(): Promise<void> {
    const defaults = [
      { id: 'work', name: 'Work', colorValue: 0xFF70A1FF, iconCodePoint: 0xe1b1 },
      { id: 'personal', name: 'Personal', colorValue: 0xFF9B5DE5, iconCodePoint: 0xe491 },
      { id: 'shopping', name: 'Shopping', colorValue: 0xFFF15BB5, iconCodePoint: 0xe59c },
      { id: 'health', name: 'Health', colorValue: 0xFF05C46B, iconCodePoint: 0xe243 },
      { id: 'study', name: 'Study', colorValue: 0xFFFF9F43, iconCodePoint: 0xe5b7 },
    ];

    for (const cat of defaults) {
      await db.category.upsert({
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
