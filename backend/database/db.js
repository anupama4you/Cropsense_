import { connect } from 'mongoose';

const MONGODB_URI = `mongodb+srv://anupama4you:anupama123@cluster0.wyuxyil.mongodb.net/?retryWrites=true&w=majority`
const connectDB = async () => {
  try {
    await connect(MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('Failed to connect to MongoDB:', error);
  }
};

export default connectDB;
