import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { randomBytes } from 'node:crypto';
import { OAuth2Client } from 'google-auth-library';
import pg from 'pg';

const { Pool } = pg;
const app = express();
const port = Number(process.env.PORT || 8080);
const googleClientId = process.env.GOOGLE_CLIENT_ID || '';
const googleOAuthClient = googleClientId ? new OAuth2Client(googleClientId) : null;

if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET wajib diatur di file .env');
}

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'buket_id',
});

app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '1mb' }));

const asyncRoute = (handler) => (req, res, next) =>
  Promise.resolve(handler(req, res, next)).catch(next);

function issueToken(user) {
  return jwt.sign(
    {
      user_id: user.id,
      email: user.email,
      role: user.role,
      username: user.username,
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' },
  );
}

function authenticate(req, res, next) {
  const header = req.get('authorization') || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

function allowRoles(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user?.role)) {
      return res.status(403).json({ error: 'Access denied' });
    }
    next();
  };
}

function validId(value) {
  const id = Number(value);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

function cleanProduct(row) {
  return {
    ...row,
    price: Number(row.price),
    rating: Number(row.rating),
    images: Array.isArray(row.images) ? row.images : [],
  };
}

async function orderWithItems(order) {
  const { rows } = await pool.query(
    `SELECT id, order_id, product_id, quantity, price
       FROM order_items WHERE order_id = $1 ORDER BY id`,
    [order.id],
  );
  return {
    ...order,
    total: Number(order.total),
    items: rows.map((item) => ({ ...item, price: Number(item.price) })),
  };
}

app.get('/health', asyncRoute(async (_req, res) => {
  await pool.query('SELECT 1');
  res.json({
    status: 'OK',
    database: 'connected',
    googleOAuthConfigured: Boolean(googleOAuthClient),
  });
}));

app.post('/api/auth/register', asyncRoute(async (req, res) => {
  const { email, username, password, phone, city } = req.body || {};
  if (!email || !/^\S+@\S+\.\S+$/.test(email) || !username || username.length < 3 ||
      !password || password.length < 6 || !phone || !city) {
    return res.status(400).json({ error: 'Email, username (min 3), password (min 6), phone, and city are required' });
  }

  const normalizedEmail = email.trim().toLowerCase();
  const hashedPassword = await bcrypt.hash(password, 12);
  try {
    const { rows } = await pool.query(
      `INSERT INTO users (email, username, password, phone, city, role)
       VALUES ($1, $2, $3, $4, $5, 'user')
       RETURNING id, email, username, phone, city, role`,
      [normalizedEmail, username.trim(), hashedPassword, phone, city],
    );
    const user = rows[0];
    res.status(201).json({ token: issueToken(user), user, message: 'User registered successfully' });
  } catch (error) {
    if (error.code === '23505') return res.status(409).json({ error: 'Email already registered' });
    throw error;
  }
}));

app.post('/api/auth/google', asyncRoute(async (req, res) => {
  if (!googleOAuthClient) {
    return res.status(503).json({ error: 'Google OAuth belum dikonfigurasi di backend' });
  }

  const idToken = String(req.body?.idToken || '');
  const city = String(req.body?.city || '').trim();
  if (!idToken) return res.status(400).json({ error: 'Google ID token wajib dikirim' });

  let payload;
  try {
    const ticket = await googleOAuthClient.verifyIdToken({
      idToken,
      audience: googleClientId,
    });
    payload = ticket.getPayload();
  } catch {
    return res.status(401).json({ error: 'Token Google tidak valid atau sudah kedaluwarsa' });
  }

  const email = String(payload?.email || '').trim().toLowerCase();
  const emailIsVerified = payload?.email_verified === true;
  const isTrustedGoogleEmail = email.endsWith('@gmail.com') || Boolean(payload?.hd);
  if (!email || !emailIsVerified || !isTrustedGoogleEmail) {
    return res.status(403).json({ error: 'Google harus mengonfirmasi kepemilikan email ini' });
  }

  const fallbackName = email.split('@')[0];
  const username = String(payload?.name || fallbackName).trim().slice(0, 100) || fallbackName;
  const randomPassword = randomBytes(48).toString('hex');
  const hashedPassword = await bcrypt.hash(randomPassword, 12);
  const { rows } = await pool.query(
    `INSERT INTO users (email, username, password, phone, city, role)
     VALUES ($1, $2, $3, NULL, $4, 'user')
     ON CONFLICT (email) DO UPDATE
       SET city = COALESCE(NULLIF(EXCLUDED.city, ''), users.city)
     RETURNING id, email, username, phone, city, role`,
    [email, username, hashedPassword, city || null],
  );

  const user = rows[0];
  res.json({ token: issueToken(user), user, message: 'Google sign-in successful' });
}));

app.post('/api/auth/login', asyncRoute(async (req, res) => {
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');
  const { rows } = await pool.query(
    'SELECT id, email, username, password, phone, city, role FROM users WHERE email = $1',
    [email],
  );
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const { password: _password, ...publicUser } = user;
  res.json({ token: issueToken(publicUser), user: publicUser, message: 'Login successful' });
}));

app.get('/api/profile', authenticate, asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    'SELECT id, email, username, phone, city, role FROM users WHERE id = $1',
    [req.user.user_id],
  );
  if (!rows[0]) return res.status(404).json({ error: 'User not found' });
  res.json(rows[0]);
}));

app.put('/api/profile', authenticate, asyncRoute(async (req, res) => {
  const { username, phone, city } = req.body || {};
  if (!username || !city) {
    return res.status(400).json({ error: 'Username and city are required' });
  }
  await pool.query(
    'UPDATE users SET username = $1, phone = $2, city = $3, updated_at = CURRENT_TIMESTAMP WHERE id = $4',
    [username, phone || null, city, req.user.user_id],
  );
  res.json({ message: 'Profile updated successfully' });
}));

app.get('/api/products', authenticate, asyncRoute(async (req, res) => {
  const filters = [];
  const values = [];
  if (req.query.city) {
    values.push(req.query.city);
    filters.push(`city = $${values.length}`);
  }
  if (req.query.category) {
    values.push(req.query.category);
    filters.push(`category = $${values.length}`);
  }
  const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
  const { rows } = await pool.query(
    `SELECT id, seller_id, name, description, price, city, category, rating, stock, images
     FROM products ${where} ORDER BY created_at DESC`,
    values,
  );
  res.json(rows.map(cleanProduct));
}));

app.get('/api/products/search', authenticate, asyncRoute(async (req, res) => {
  const term = `%${String(req.query.q || '').trim()}%`;
  const { rows } = await pool.query(
    `SELECT id, seller_id, name, description, price, city, category, rating, stock, images
     FROM products WHERE name ILIKE $1 OR COALESCE(description, '') ILIKE $1
     ORDER BY created_at DESC`,
    [term],
  );
  res.json(rows.map(cleanProduct));
}));

app.get('/api/products/:id', authenticate, asyncRoute(async (req, res) => {
  const id = validId(req.params.id);
  if (!id) return res.status(404).json({ error: 'Product not found' });
  const { rows } = await pool.query(
    `SELECT id, seller_id, name, description, price, city, category, rating, stock, images
     FROM products WHERE id = $1`,
    [id],
  );
  if (!rows[0]) return res.status(404).json({ error: 'Product not found' });
  res.json(cleanProduct(rows[0]));
}));

app.post('/api/seller/products', authenticate, allowRoles('seller', 'admin'), asyncRoute(async (req, res) => {
  const { name, description, price, city, category, stock, images = [] } = req.body || {};
  if (!name || !description || !city || !category || !Number.isFinite(Number(price)) ||
      Number(price) <= 0 || !Number.isInteger(Number(stock)) || Number(stock) < 0 || !Array.isArray(images)) {
    return res.status(400).json({ error: 'Valid product fields are required' });
  }
  const { rows: sellers } = await pool.query('SELECT id FROM sellers WHERE user_id = $1', [req.user.user_id]);
  if (!sellers[0]) return res.status(403).json({ error: 'You must be a seller to create products' });
  const { rows } = await pool.query(
    `INSERT INTO products (seller_id, name, description, price, city, category, stock, images)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb) RETURNING id`,
    [sellers[0].id, name, description, price, city, category, stock, JSON.stringify(images)],
  );
  res.status(201).json({ message: 'Product created', id: rows[0].id });
}));

async function ownedProduct(req, res) {
  const productId = validId(req.params.id);
  if (!productId) {
    res.status(404).json({ error: 'Product not found' });
    return null;
  }
  const { rows } = await pool.query(
    `SELECT p.id, p.seller_id, s.user_id
       FROM products p JOIN sellers s ON s.id = p.seller_id
      WHERE p.id = $1`,
    [productId],
  );
  const product = rows[0];
  if (!product) {
    res.status(404).json({ error: 'Product not found' });
    return null;
  }
  if (req.user.role !== 'admin' && product.user_id !== req.user.user_id) {
    res.status(403).json({ error: 'You can only manage your own products' });
    return null;
  }
  return product;
}

app.put('/api/seller/products/:id', authenticate, allowRoles('seller', 'admin'), asyncRoute(async (req, res) => {
  const product = await ownedProduct(req, res);
  if (!product) return;
  const fields = ['name', 'description', 'price', 'city', 'category', 'stock', 'images'];
  const sets = [];
  const values = [];
  for (const field of fields) {
    if (req.body?.[field] === undefined) continue;
    const value = field === 'images' ? JSON.stringify(req.body[field]) : req.body[field];
    values.push(value);
    sets.push(`${field} = $${values.length}${field === 'images' ? '::jsonb' : ''}`);
  }
  if (sets.length === 0) return res.status(400).json({ error: 'No product fields provided' });
  values.push(product.id);
  await pool.query(
    `UPDATE products SET ${sets.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = $${values.length}`,
    values,
  );
  res.json({ message: 'Product updated successfully' });
}));

app.delete('/api/seller/products/:id', authenticate, allowRoles('seller', 'admin'), asyncRoute(async (req, res) => {
  const product = await ownedProduct(req, res);
  if (!product) return;
  await pool.query('DELETE FROM products WHERE id = $1', [product.id]);
  res.json({ message: 'Product deleted successfully' });
}));

app.get('/api/cart', authenticate, asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT ci.id, ci.product_id, ci.quantity, p.name, p.price, p.images
       FROM cart_items ci JOIN products p ON p.id = ci.product_id
      WHERE ci.user_id = $1 ORDER BY ci.id`,
    [req.user.user_id],
  );
  let total = 0;
  const items = rows.map((row) => {
    const price = Number(row.price);
    const itemTotal = price * row.quantity;
    total += itemTotal;
    return { ...row, price, total: itemTotal, images: Array.isArray(row.images) ? row.images : [] };
  });
  res.json({ items, total });
}));

app.post('/api/cart', authenticate, asyncRoute(async (req, res) => {
  const productId = validId(req.body?.product_id);
  const quantity = Number(req.body?.quantity);
  if (!productId || !Number.isInteger(quantity) || quantity < 1) {
    return res.status(400).json({ error: 'Valid product_id and positive quantity are required' });
  }
  const { rowCount } = await pool.query('SELECT 1 FROM products WHERE id = $1', [productId]);
  if (!rowCount) return res.status(404).json({ error: 'Product not found' });
  await pool.query(
    `INSERT INTO cart_items (user_id, product_id, quantity) VALUES ($1, $2, $3)
     ON CONFLICT (user_id, product_id)
     DO UPDATE SET quantity = cart_items.quantity + EXCLUDED.quantity`,
    [req.user.user_id, productId, quantity],
  );
  res.json({ message: 'Product added to cart' });
}));

app.put('/api/cart/:id', authenticate, asyncRoute(async (req, res) => {
  const id = validId(req.params.id);
  const quantity = Number(req.body?.quantity);
  if (!id || !Number.isInteger(quantity) || quantity < 1) {
    return res.status(400).json({ error: 'Valid item id and positive quantity are required' });
  }
  const { rowCount } = await pool.query(
    'UPDATE cart_items SET quantity = $1 WHERE id = $2 AND user_id = $3',
    [quantity, id, req.user.user_id],
  );
  if (!rowCount) return res.status(404).json({ error: 'Cart item not found' });
  res.json({ message: 'Cart item updated' });
}));

app.delete('/api/cart/:id', authenticate, asyncRoute(async (req, res) => {
  const id = validId(req.params.id);
  if (!id) return res.status(400).json({ error: 'Invalid cart item id' });
  const { rowCount } = await pool.query(
    'DELETE FROM cart_items WHERE id = $1 AND user_id = $2',
    [id, req.user.user_id],
  );
  if (!rowCount) return res.status(404).json({ error: 'Cart item not found' });
  res.json({ message: 'Item removed from cart' });
}));

app.delete('/api/cart', authenticate, asyncRoute(async (req, res) => {
  await pool.query('DELETE FROM cart_items WHERE user_id = $1', [req.user.user_id]);
  res.json({ message: 'Cart cleared' });
}));

app.post('/api/orders', authenticate, asyncRoute(async (req, res) => {
  const items = req.body?.items;
  if (!Array.isArray(items) || items.length === 0 || items.some((item) =>
    !validId(item?.product_id) || !Number.isInteger(Number(item?.quantity)) || Number(item.quantity) < 1)) {
    return res.status(400).json({ error: 'Order must contain valid items' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    let total = 0;
    let sellerId = null;
    const orderItems = [];
    for (const item of items) {
      const productId = validId(item.product_id);
      const quantity = Number(item.quantity);
      const { rows } = await client.query(
        'SELECT id, seller_id, price, stock FROM products WHERE id = $1 FOR UPDATE',
        [productId],
      );
      const product = rows[0];
      if (!product) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Product not found' });
      }
      if (product.stock < quantity) {
        await client.query('ROLLBACK');
        return res.status(409).json({ error: `Insufficient stock for product ${productId}` });
      }
      if (sellerId === null) sellerId = product.seller_id;
      if (sellerId !== product.seller_id) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'An order can contain products from one seller only' });
      }
      const price = Number(product.price);
      total += price * quantity;
      orderItems.push({ productId, quantity, price });
    }

    const { rows: orders } = await client.query(
      `INSERT INTO orders (user_id, seller_id, total, status)
       VALUES ($1, $2, $3, 'pending') RETURNING id`,
      [req.user.user_id, sellerId, total],
    );
    const orderId = orders[0].id;
    for (const item of orderItems) {
      await client.query(
        'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES ($1, $2, $3, $4)',
        [orderId, item.productId, item.quantity, item.price],
      );
      await client.query('UPDATE products SET stock = stock - $1 WHERE id = $2', [item.quantity, item.productId]);
    }
    await client.query('COMMIT');
    res.status(201).json({ message: 'Order created successfully', order_id: orderId, total });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}));

app.get('/api/orders', authenticate, asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    'SELECT id, user_id, seller_id, total, status, created_at FROM orders WHERE user_id = $1 ORDER BY created_at DESC',
    [req.user.user_id],
  );
  res.json(await Promise.all(rows.map(orderWithItems)));
}));

app.get('/api/orders/:id', authenticate, asyncRoute(async (req, res) => {
  const id = validId(req.params.id);
  if (!id) return res.status(404).json({ error: 'Order not found' });
  const { rows } = await pool.query(
    'SELECT id, user_id, seller_id, total, status, created_at FROM orders WHERE id = $1 AND user_id = $2',
    [id, req.user.user_id],
  );
  if (!rows[0]) return res.status(404).json({ error: 'Order not found' });
  res.json(await orderWithItems(rows[0]));
}));

app.get('/api/seller/orders', authenticate, allowRoles('seller', 'admin'), asyncRoute(async (req, res) => {
  const { rows: sellers } = await pool.query('SELECT id FROM sellers WHERE user_id = $1', [req.user.user_id]);
  if (!sellers[0] && req.user.role !== 'admin') return res.status(403).json({ error: 'You are not a seller' });
  const { rows } = req.user.role === 'admin'
    ? await pool.query('SELECT id, user_id, seller_id, total, status, created_at FROM orders ORDER BY created_at DESC')
    : await pool.query('SELECT id, user_id, seller_id, total, status, created_at FROM orders WHERE seller_id = $1 ORDER BY created_at DESC', [sellers[0].id]);
  res.json(await Promise.all(rows.map(orderWithItems)));
}));

app.put('/api/seller/orders/:id', authenticate, allowRoles('seller', 'admin'), asyncRoute(async (req, res) => {
  const id = validId(req.params.id);
  const { status } = req.body || {};
  const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  if (!id || !validStatuses.includes(status)) return res.status(400).json({ error: 'Invalid order id or status' });
  if (req.user.role !== 'admin') {
    const { rows: sellers } = await pool.query('SELECT id FROM sellers WHERE user_id = $1', [req.user.user_id]);
    if (!sellers[0]) return res.status(403).json({ error: 'You are not a seller' });
    const { rowCount } = await pool.query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND seller_id = $3',
      [status, id, sellers[0].id],
    );
    if (!rowCount) return res.status(404).json({ error: 'Order not found' });
  } else {
    const { rowCount } = await pool.query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [status, id],
    );
    if (!rowCount) return res.status(404).json({ error: 'Order not found' });
  }
  res.json({ message: 'Order status updated' });
}));

app.get('/api/admin/stats', authenticate, allowRoles('admin'), asyncRoute(async (_req, res) => {
  const { rows } = await pool.query(
    `SELECT (SELECT COUNT(*) FROM users) AS users,
            (SELECT COUNT(*) FROM products) AS products,
            (SELECT COUNT(*) FROM orders) AS orders`,
  );
  res.json(rows[0]);
}));

app.use((req, res) => res.status(404).json({ error: 'Route not found' }));
app.use((error, _req, res, _next) => {
  console.error(error);
  if (error.type === 'entity.parse.failed') return res.status(400).json({ error: 'Invalid JSON body' });
  res.status(500).json({ error: 'Internal server error' });
});

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`Buket.id API running on port ${port}`);
});

async function shutdown() {
  server.close();
  await pool.end();
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
