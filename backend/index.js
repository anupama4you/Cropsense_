import { Configuration, OpenAIApi } from "openai";
import express from 'express';
import bodyParser from "body-parser";
import cors from "cors";
import connectDB from './database/db.js';
import router from './database/routes.js';
import fetch from "node-fetch"; // Import fetch
import Replicate from "replicate";

const configuration = new Configuration({
    apiKey: "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"
});



const openai = new OpenAIApi(configuration);

//These arrays are to maintain the history of the conversation
const conversationContext = [];
const currentMessages = [];

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

// Connect to MongoDB
connectDB();

// Routes
app.use('/', router);

app.post("/", async (req, res) => {
    try {
        const { prompt } = req.body;
        const modelId = "gpt-3.5-turbo";
        const promptText = `${prompt}`;

        // Initialize conversation with a system message to set the context
        const initialMessage = {
            role: "system",
            content: "You are a helpful assistant that specializes in agriculture and leaf disease detection who provides short and concise answers for users' questions. If the user’s question is not directly related to these topics, politely redirect them or suggest they seek information elsewhere.",
        };

        // Restore the previous context
        const currentMessages = [initialMessage];
        for (const [inputText, responseText] of conversationContext) {
            currentMessages.push({ role: "user", content: inputText });
            currentMessages.push({ role: "assistant", content: responseText });
        }

        // Stores the new message
        currentMessages.push({ role: "user", content: promptText });

        const result = await openai.createChatCompletion({
            model: modelId,
            messages: currentMessages,
            temperature: 0.2
        });

        const responseText = result.data.choices[0].message.content;
        conversationContext.push([promptText, responseText]);
        res.send({ response: responseText });

    } catch (error) {
        console.error("Error in POST request:", error);
        res.status(400).send({ error: "Bad request" });
    }
});


app.listen(port, () => {
    console.log(`chat-gpt API testing app listening at http://localhost:${port})`)
});
