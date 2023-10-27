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

// app.post("/", async (req, res) => {
//     try {
//         const { prompt } = req.body;
//         const modelId = "gpt-3.5-turbo";
//         const promptText = `${prompt}\n\nResponse:`;

//         // Restore the previous context
//         for (const [inputText, responseText] of conversationContext) {
//             currentMessages.push({ role: "user", content: inputText });
//             currentMessages.push({ role: "assistant", content: responseText });
//         }

//         // Stores the new message
//         currentMessages.push({ role: "user", content: promptText });

//         const result = await openai.createChatCompletion({
//         model: modelId,
//         messages: currentMessages,
//         });

//         const responseText = result.data.choices.shift().message.content;
//         conversationContext.push([promptText, responseText]);
//         res.send({ response: responseText });

//     } catch (error) {
//         console.error("Error in POST request:", error);
//         res.status(400).send({ error: "Bad request" });
//     }
// });

app.post("/", async (req, res) => {
    try {
      // Assuming the filename is sent in the request body
      const { image, filename } = req.body;

      var realFile = Buffer.from(image,"base64");

      console.log(realFile)

      if (!filename) {
        return res.status(400).json({ error: "Filename is missing from the request body" });
      }
  
      // Read the file from the provided filename
    //   const data = fs.readFileSync(filename);
        fs.writeFileSync(filename, realFile);
  
      // Replace {API_TOKEN} with your actual API token
      const API_TOKEN = "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";
  
      // Make the POST request to the Hugging Face API
      const response = await fetch("https://api-inference.huggingface.co/models/yusuf802/Leaf-Disease-Predictor", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${API_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ data: data.toString() }), // Convert the data to a string
      });
  
      if (response.status !== 200) {
        return res.status(response.status).json({ error: "Failed to get a valid response from the API" });
      }
  
      const result = await response.json();
      return res.json(result);
    } catch (error) {
      console.error(error);
      return res.status(500).json({ error: "Internal server error" });
    }
  });

app.listen(port, () => {
    console.log(`chat-gpt API testing app listening at http://localhost:${port})`)
});
