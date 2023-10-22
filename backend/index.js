import { Configuration, OpenAIApi } from "openai";
import express from 'express';
import bodyParser from "body-parser";
import cors from "cors";
import connectDB from './database/db.js';
import router from './database/routes.js';
import fetch from "node-fetch"; // Import fetch
import Replicate from "replicate";

const configuration = new Configuration({
    organization: "org-b3Y1ILtBwy8Bb77EVwceDrf6",
    apiKey: "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"
});

const replicate = new Replicate({
    auth: "r8_LYfRgooa3gNAGEfY36lxIlP3IWkFo7u0uuoaK",
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
        const promptText = `${prompt}\n\nResponse:`;

        // Restore the previous context
        for (const [inputText, responseText] of conversationContext) {
            currentMessages.push({ role: "user", content: inputText });
            currentMessages.push({ role: "assistant", content: responseText });
        }

        // Stores the new message
        currentMessages.push({ role: "user", content: promptText });

        const result = await openai.createChatCompletion({
        model: modelId,
        messages: currentMessages,
        });

        const responseText = result.data.choices.shift().message.content;
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
