import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { createServer } from 'http';

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(bodyParser.json());



const httpServer = createServer(app);

httpServer.listen(PORT, () => {
  console.log(`Server ready at http://localhost:${PORT}`);
});

httpServer.on('error', (error) => {
    console.error('Error starting server:', error);
});

export default app;