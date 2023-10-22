import express from 'express';
const router = express.Router();
import Result from './result.js';

// GET all results
router.get('/results', async (req, res) => {
  try {
    const results = await Result.find();
    res.json(results);
  } catch (error) {
    console.error('Failed to fetch results:', error);
    res.status(500).json({ error: 'Failed to fetch results' });
  }
});

// POST a new result
router.post('/results', async (req, res) => {
  try {
    const newResult = await Result.create(req.body);
    res.status(201).json(newResult);
  } catch (error) {
    console.error('Failed to create result:', error);
    res.status(500).json({ error: 'Failed to create result' });
  }
});

export default router;
