# 🚀 Backend Setup Guide - COOVI API

**Project:** coovi-api  
**Tech Stack:** Express.js + TypeScript + Mongoose + MongoDB Atlas

---

## 📋 Prerequisites

- ✅ Node.js 24 installed
- ✅ pnpm installed
- ✅ MongoDB Atlas account created
- ✅ MongoDB connection string ready
- ✅ Git installed

---

## 🏗️ Step 1: Initialize Project

### Create project folder (you'll do this at home):

```bash
# Navigate to your projects folder
cd /path/to/coovi-projects

# Create backend folder
mkdir coovi-api
cd coovi-api
```

### Initialize Node.js project:

```bash
# Initialize package.json
pnpm init

# This creates package.json with defaults
```

---

## 📦 Step 2: Install Dependencies

```bash
# Production dependencies
pnpm add express mongoose cors dotenv bcrypt jsonwebtoken cloudinary multer

# Development dependencies
pnpm add -D typescript @types/node @types/express @types/cors @types/bcrypt @types/jsonwebtoken @types/multer ts-node-dev
```

**What each package does:**
- `express` → Web framework
- `mongoose` → MongoDB ODM
- `cors` → Enable cross-origin requests from storefront/admin
- `dotenv` → Load environment variables
- `bcrypt` → Hash admin passwords
- `jsonwebtoken` → Admin authentication tokens
- `cloudinary` → Image upload service
- `multer` → Handle file uploads
- `ts-node-dev` → Run TypeScript with auto-reload

---

## 📝 Step 3: Initialize TypeScript

```bash
# Generate tsconfig.json
npx tsc --init
```

### Edit `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

---

## 📁 Step 4: Create Folder Structure

```bash
# Create folders
mkdir -p src/config src/models src/routes src/controllers src/middleware src/types src/utils
```

**Final structure:**
```
coovi-api/
├── src/
│   ├── config/
│   │   └── database.ts
│   ├── models/
│   │   ├── Product.ts
│   │   ├── Order.ts
│   │   └── Admin.ts
│   ├── routes/
│   │   ├── products.ts
│   │   ├── orders.ts
│   │   └── auth.ts
│   ├── controllers/
│   ├── middleware/
│   ├── types/
│   │   └── index.ts
│   ├── utils/
│   └── index.ts
├── .env
├── .gitignore
├── package.json
└── tsconfig.json
```

---

## 🔐 Step 5: Setup Environment Variables

### Create `.env` file:

```env
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb+srv://username:password@coovi-cluster.xxxxx.mongodb.net/coovi
JWT_SECRET=your_super_secret_jwt_key_change_this
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
DELIVERY_FEE=60
CLIENT_URL=http://localhost:3000
ADMIN_URL=http://localhost:5173
```

---

## 📄 Step 6: Create Database Connection

### `src/config/database.ts`:

```typescript
import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || '';

export const connectDB = async (): Promise<void> => {
  try {
    const conn = await mongoose.connect(MONGODB_URI);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error);
    process.exit(1);
  }
};
```

---

## 🗄️ Step 7: Create TypeScript Types

### `src/types/index.ts`:

```typescript
import { Document } from 'mongoose';

export interface IProduct extends Document {
  slug: string;
  name: string;
  price: number;
  images: string[];
  category: string;
  size?: string;
  description?: string;
  inStock: boolean;
  stockCount: number;
  featured: boolean;
}

export interface IOrder extends Document {
  orderNumber: string;
  customerName: string;
  phone: string;
  email?: string;
  address: {
    street: string;
    city: string;
    district: string;
    postalCode: string;
  };
  items: Array<{
    productId: string;
    name: string;
    price: number;
    quantity: number;
    image: string;
  }>;
  subtotal: number;
  deliveryFee: number;
  total: number;
  paymentMethod: 'COD';
  status: 'Pending' | 'Processing' | 'Shipped' | 'Delivered' | 'Cancelled';
  notes?: string;
}

export interface IAdmin extends Document {
  email: string;
  password: string;
  name: string;
  role: string;
  comparePassword(candidatePassword: string): Promise<boolean>;
}
```

---

## 📜 Step 8: Update package.json

```json
{
  "name": "coovi-api",
  "version": "1.0.0",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
```

---

## 🚫 Step 9: Create .gitignore

```gitignore
node_modules/
.env
dist/
*.log
.DS_Store
```

---

## ✅ Next: Create Models & Routes

Continue to the next guide to build the complete API!
