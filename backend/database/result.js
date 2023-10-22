import mongoose from 'mongoose';

const resultSchema = new mongoose.Schema({
  prediction: String,
  details: String,
  symptoms: String,
  treatments: String,
  preventiveMeasures: String,
});

const Result = mongoose.model('Result', resultSchema);

export default Result;
