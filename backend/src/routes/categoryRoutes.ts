import { Router } from 'express';
import { CategoryController, createCategorySchema } from '../controllers/categoryController';
import { validateRequest } from '../middleware/validation';

const router = Router();

router.get('/', CategoryController.getAll);
router.post('/', validateRequest({ body: createCategorySchema }), CategoryController.create);
router.delete('/:id', CategoryController.delete);

export default router;
