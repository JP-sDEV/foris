import express from 'express';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';

// Define the expected request body shape
interface TokenRequestBody {
  sub: string;
  email: string;
  name: string;
}

const app = express();
const PORT = process.env.PORT || 8080;

// Enable JSON body parsing
app.use(express.json());

// Load private key for signing the id_token
const privateKeyPath = path.join(__dirname, 'private.key');
const privateKey = fs.readFileSync(privateKeyPath, 'utf8');

// POST /token endpoint
app.post('/token', (req: any, res: any) => {
  const { sub, email, name } = req.body as TokenRequestBody;

  if (!sub || !email || !name) {
    return res
      .status(400)
      .json({ error: 'Missing sub, email, or name in request body' });
  }

  const now = Math.floor(Date.now() / 1000);

  const idToken = jwt.sign(
    {
      sub,
      email,
      name,
      aud: 'local-testing-client',
      iss: `http://localhost:${PORT}`,
      iat: now,
      exp: now + 3600,
    },
    privateKey,
    { algorithm: 'RS256' },
  );

  res.json({
    access_token: 'mock-access-token',
    refresh_token: 'mock-refresh-token',
    id_token: idToken,
    token_type: 'Bearer',
    expires_in: 3600,
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Mock OAuth server running at http://localhost:${PORT}`);
});
