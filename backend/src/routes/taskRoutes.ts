import { Router } from 'express';
import { TaskController, createTaskSchema, updateTaskSchema } from '../controllers/taskController';
import { validateRequest } from '../middleware/validation';

const router = Router();

router.get('/', TaskController.getAll);
router.get('/:id', TaskController.getById);
router.post('/', validateRequest({ body: createTaskSchema }), TaskController.create);
router.put('/:id', validateRequest({ body: updateTaskSchema }), TaskController.update);
router.delete('/:id', TaskController.delete);
router.patch('/:id/toggle', TaskController.toggleTask);
router.patch('/:id/subtasks/:subtaskId/toggle', TaskController.toggleSubtask);

export default router;
