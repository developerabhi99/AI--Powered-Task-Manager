import { db } from './db';
import { BadRequestError, NotFoundError } from '../utils/errors';
import { Task, Subtask } from '@prisma/client';
import { randomUUID } from 'crypto';
import { CategoryWithIntColor } from './categoryService';

export type TaskWithRelations = Task & {
  category: CategoryWithIntColor;
  subtasks: Subtask[];
};

export class TaskService {
  private static mapTask(task: any): TaskWithRelations {
    if (!task) return task;
    return {
      ...task,
      category: {
        ...task.category,
        colorValue: Number(task.category.colorValue),
      },
    };
  }

  public static async getAll(filters: {
    categoryId?: string;
    isCompleted?: boolean;
    search?: string;
  } = {}): Promise<TaskWithRelations[]> {
    const whereClause: any = {};

    // Filter by Category
    if (filters.categoryId && filters.categoryId !== 'all') {
      whereClause.categoryId = filters.categoryId;
    }

    // Filter by Status
    if (filters.isCompleted !== undefined) {
      whereClause.isCompleted = filters.isCompleted;
    }

    // Filter by Search Query (title or description)
    if (filters.search) {
      whereClause.OR = [
        { title: { contains: filters.search, mode: 'insensitive' } },
        { description: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const tasks = await db.task.findMany({
      where: whereClause,
      include: {
        category: true,
        subtasks: true,
      },
      orderBy: {
        dueDate: 'desc',
      },
    });

    return tasks.map(this.mapTask);
  }

  public static async getById(id: string): Promise<TaskWithRelations> {
    const task = await db.task.findUnique({
      where: { id },
      include: {
        category: true,
        subtasks: true,
      },
    });

    if (!task) {
      throw new NotFoundError(`Task with ID "${id}" not found`);
    }

    return this.mapTask(task);
  }

  public static async create(data: {
    id?: string;
    title: string;
    description?: string;
    dueDate: Date;
    priority?: string;
    categoryId: string;
    duration?: number;
    reminderMinutes?: number;
    subtasks?: { title: string; isCompleted?: boolean }[];
  }): Promise<TaskWithRelations> {
    // Validate Category exists
    const categoryExists = await db.category.findUnique({
      where: { id: data.categoryId },
    });
    if (!categoryExists) {
      throw new BadRequestError(`Category with ID "${data.categoryId}" does not exist`);
    }

    const taskId = data.id || randomUUID();

    // Create task along with its subtasks
    const task = await db.task.create({
      data: {
        id: taskId,
        title: data.title,
        description: data.description || '',
        dueDate: data.dueDate,
        priority: data.priority || 'medium',
        isCompleted: false,
        categoryId: data.categoryId,
        duration: data.duration ?? 0,
        reminderMinutes: data.reminderMinutes ?? -1,
        subtasks: {
          create: (data.subtasks || []).map((s) => ({
            id: randomUUID(),
            title: s.title,
            isCompleted: s.isCompleted || false,
          })),
        },
      },
      include: {
        category: true,
        subtasks: true,
      },
    });

    return this.mapTask(task);
  }

  public static async update(
    id: string,
    data: {
      title?: string;
      description?: string;
      dueDate?: Date;
      priority?: string;
      isCompleted?: boolean;
      categoryId?: string;
      duration?: number;
      reminderMinutes?: number;
      subtasks?: { id?: string; title: string; isCompleted: boolean }[];
    }
  ): Promise<TaskWithRelations> {
    // Check if task exists
    const existingTask = await this.getById(id);

    // Validate Category if changing
    if (data.categoryId) {
      const categoryExists = await db.category.findUnique({
        where: { id: data.categoryId },
      });
      if (!categoryExists) {
        throw new BadRequestError(`Category with ID "${data.categoryId}" does not exist`);
      }
    }

    // Handle subtasks sync
    const updateData: any = {
      title: data.title,
      description: data.description,
      dueDate: data.dueDate,
      priority: data.priority,
      isCompleted: data.isCompleted,
      categoryId: data.categoryId,
      duration: data.duration,
      reminderMinutes: data.reminderMinutes,
    };

    if (data.subtasks) {
      const existingSubtaskIds = existingTask.subtasks.map((s) => s.id);
      const incomingSubtasks = data.subtasks;
      const incomingSubtaskIds = incomingSubtasks
        .map((s) => s.id)
        .filter((sid): sid is string => !!sid);

      // Subtasks to delete
      const subtasksToDelete = existingSubtaskIds.filter((sid) => !incomingSubtaskIds.includes(sid));

      // Subtasks to update
      const subtasksToUpdate = incomingSubtasks.filter((s) => s.id && existingSubtaskIds.includes(s.id));

      // Subtasks to create
      const subtasksToCreate = incomingSubtasks.filter((s) => !s.id);

      // Run transactional updates
      await db.$transaction(async (tx) => {
        // Delete removed subtasks
        if (subtasksToDelete.length > 0) {
          await tx.subtask.deleteMany({
            where: { id: { in: subtasksToDelete } },
          });
        }

        // Update existing subtasks
        for (const sub of subtasksToUpdate) {
          await tx.subtask.update({
            where: { id: sub.id },
            data: {
              title: sub.title,
              isCompleted: sub.isCompleted,
            },
          });
        }

        // Create new subtasks
        if (subtasksToCreate.length > 0) {
          await tx.subtask.createMany({
            data: subtasksToCreate.map((s) => ({
              id: randomUUID(),
              taskId: id,
              title: s.title,
              isCompleted: s.isCompleted,
            })),
          });
        }
      });
    }

    // Refresh isCompleted status of main task based on final subtasks state if isCompleted is not explicitly set
    if (data.subtasks && data.isCompleted === undefined) {
      const finalSubtasks = await db.subtask.findMany({
        where: { taskId: id },
      });

      if (finalSubtasks.length > 0) {
        const allDone = finalSubtasks.every((s) => s.isCompleted);
        const anyActive = finalSubtasks.some((s) => !s.isCompleted);
        
        if (allDone) {
          updateData.isCompleted = true;
        } else if (anyActive && existingTask.isCompleted) {
          updateData.isCompleted = false;
        }
      }
    }

    const updated = await db.task.update({
      where: { id },
      data: updateData,
      include: {
        category: true,
        subtasks: true,
      },
    });

    return this.mapTask(updated);
  }

  public static async delete(id: string): Promise<Task> {
    // Check if exists
    await this.getById(id);

    return db.task.delete({
      where: { id },
    });
  }

  // Toggles the entire task status
  public static async toggleTaskCompletion(id: string): Promise<TaskWithRelations> {
    const task = await this.getById(id);
    const newStatus = !task.isCompleted;

    // Use transaction to update task and all of its subtasks
    const updated = await db.$transaction(async (tx) => {
      // Update all subtasks to match the new status
      await tx.subtask.updateMany({
        where: { taskId: id },
        data: { isCompleted: newStatus },
      });

      // Update main task
      return tx.task.update({
        where: { id },
        data: { isCompleted: newStatus },
        include: {
          category: true,
          subtasks: true,
        },
      });
    });

    return this.mapTask(updated);
  }

  // Toggles single subtask completion status and adjusts the parent task
  public static async toggleSubtaskCompletion(
    taskId: string,
    subtaskId: string
  ): Promise<TaskWithRelations> {
    const task = await this.getById(taskId);
    const subtask = task.subtasks.find((s) => s.id === subtaskId);

    if (!subtask) {
      throw new NotFoundError(`Subtask with ID "${subtaskId}" not found on this task`);
    }

    const newSubStatus = !subtask.isCompleted;

    const updated = await db.$transaction(async (tx) => {
      // Toggle subtask status
      await tx.subtask.update({
        where: { id: subtaskId },
        data: { isCompleted: newSubStatus },
      });

      // Fetch all subtasks after update to calculate new task status
      const allSubtasks = await tx.subtask.findMany({
        where: { taskId },
      });

      const allDone = allSubtasks.every((s) => s.isCompleted);
      const anyActive = allSubtasks.some((s) => !s.isCompleted);

      let isTaskCompleted = task.isCompleted;
      if (allDone) {
        isTaskCompleted = true;
      } else if (anyActive && task.isCompleted) {
        isTaskCompleted = false;
      }

      // Update parent task
      return tx.task.update({
        where: { id: taskId },
        data: { isCompleted: isTaskCompleted },
        include: {
          category: true,
          subtasks: true,
        },
      });
    });

    return this.mapTask(updated);
  }
}
