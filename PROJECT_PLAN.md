# Diponty Clone - Learning by Building Plan

## 🎯 Project Overview

**Three Separate Projects:**

1. **Storefront** → Next.js 16 + Tailwind CSS (customer-facing e-commerce) - **TypeScript**
2. **Admin Panel** → React 19 + Vite + Tailwind CSS (management dashboard) - **TypeScript**
3. **Backend API** → Node.js + Express + Mongoose (shared API for both) - **TypeScript**

**Database:** MongoDB Atlas (Free tier - 512MB)

**Design:** Mobile-first responsive (all styles written for mobile, then scale up)

**Learning Approach:** Start with basics, add features incrementally as you learn.

---

## 📦 Project Structure (3 Separate Folders)

```
projects/
├── diponty-storefront/          # Next.js 16 customer site
├── diponty-admin/               # React 19 admin panel  
└── diponty-api/                 # Express.js backend
```

Each is a **completely separate project** with its own `package.json`, Git repo, and deployment.

---

## 🎨 Brand Color Configuration (Tailwind)

We'll set up a **theme system** where you change ONE file and the entire storefront updates.

### Example: `tailwind.config.js` (Storefront)

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // 🎨 CHANGE THESE TO YOUR BRAND COLORS
        brand: {
          primary: '#FF6B6B',      // Main brand color (buttons, links)
          secondary: '#4ECDC4',    // Secondary color (accents)
          dark: '#1A1A1A',         // Dark text/backgrounds
          light: '#F7F7F7',        // Light backgrounds
        },
        // Product-related colors (can stay neutral)
        product: {
          card: '#FFFFFF',
          border: '#E5E5E5',
          hover: '#F9F9F9',
        },
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        bengali: ['Noto Sans Bengali', 'sans-serif'],
      },
      // Mobile-first breakpoints (Tailwind defaults)
      screens: {
        'sm': '640px',   // Small devices (landscape phones)
        'md': '768px',   // Medium devices (tablets)
        'lg': '1024px',  // Large devices (desktops)
        'xl': '1280px',  // Extra large devices
        '2xl': '1536px', // 2X Extra large devices
      },
    },
  },
  plugins: [],
}
```

### Mobile-First Responsive Design Principles:

**Write CSS for mobile FIRST, then add larger screen styles:**

```jsx
// ❌ WRONG - Desktop first
<div className="grid-cols-4 md:grid-cols-2 sm:grid-cols-1">

// ✅ CORRECT - Mobile first
<div className="grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
```

**Responsive Design Rules:**

1. **Base styles = Mobile styles** (no prefix)
   ```jsx
   <button className="w-full text-sm px-4 py-2">
   ```

2. **Add larger screens progressively** (sm, md, lg, xl)
   ```jsx
   <button className="w-full sm:w-auto md:px-6 md:py-3 lg:text-base">
   ```

3. **Common responsive patterns:**
   ```jsx
   // Product grid: 1 col mobile → 2 col tablet → 4 col desktop
   <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
   
   // Hide on mobile, show on desktop
   <div className="hidden md:block">
   
   // Show on mobile, hide on desktop
   <div className="block md:hidden">
   
   // Padding: small on mobile, larger on desktop
   <div className="px-4 py-6 md:px-8 md:py-10 lg:px-16 lg:py-12">
   
   // Text size: small on mobile, larger on desktop
   <h1 className="text-2xl md:text-4xl lg:text-5xl">
   ```

### Usage in Components:

```jsx
// Button with brand colors
<button className="bg-brand-primary hover:bg-brand-secondary text-white">
  Add to Cart
</button>

// Responsive product card
<div className="bg-product-card border border-product-border hover:bg-product-hover">
  Product content
</div>

// Mobile-first product grid
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 md:gap-6">
  {products.map(product => <ProductCard key={product.id} />)}
</div>
```

**When you finalize your brand:** Just change `#FF6B6B` to your color → entire site updates! ✨

---

## 🚀 Learning Path (Start Basic → Add Features)

### **Level 1: Foundation (Week 1-2)** ⭐ START HERE

Build the absolute minimum to see something working.

#### Storefront:
- [ ] Create Next.js 16 project
- [ ] Setup Tailwind with brand colors
- [ ] Create basic layout (Header + Footer)
- [ ] Make a simple homepage
- [ ] Create ONE static product card
- [ ] Style it to look nice

#### Backend:
- [ ] Create Express.js API (TypeScript)
- [ ] Setup Mongoose + MongoDB Atlas (free tier)
- [ ] Create Product model
- [ ] Make ONE API endpoint: `GET /api/products`
- [ ] Add 3-5 sample products manually

#### Admin Panel:
- [ ] ⏸️ Skip for now (Week 1-2)

**Goal:** Display 5 products on homepage fetched from API. Nothing fancy, just working.

---

### **Level 2: Product Catalog (Week 3-4)** 🛍️

Add product browsing functionality.

#### Storefront:
- [ ] Product listing page (`/products`)
- [ ] Display all products in a grid
- [ ] Product detail page (`/products/[slug]`)
- [ ] Image hover effect (swap to 2nd image)
- [ ] Basic search (filter by name)
- [ ] Sort by price (low to high, high to low)

#### Backend:
- [ ] `GET /api/products/:slug` (single product)
- [ ] Add pagination to product list
- [ ] Add filtering/sorting logic with MongoDB queries
- [ ] Add more sample products (20+)

#### Admin Panel:
- [ ] ⏸️ Still skip (add products manually in database)

**Goal:** Browse products, click to see details, search and sort working.

---

### **Level 3: Shopping Cart (Week 5-6)** 🛒

Add cart functionality (no checkout yet).

#### Storefront:
- [ ] Setup Zustand for cart state
- [ ] "Add to Cart" button on product card
- [ ] Cart icon in header (shows item count)
- [ ] Cart page (`/cart`)
- [ ] Increase/decrease quantity
- [ ] Remove item from cart
- [ ] Calculate total price
- [ ] Save cart in `localStorage` (persists on refresh)

#### Backend:
- [ ] No backend needed for cart (client-side only)

#### Admin Panel:
- [ ] ⏸️ Still skip

**Goal:** Add products to cart, see total, items persist after refresh.

---

### **Level 4: Checkout (Week 7-8)** 💳

Complete the order flow with Cash on Delivery.

#### Storefront:
- [ ] Checkout page (`/checkout`)
- [ ] Checkout form (name, phone, address)
- [ ] Form validation (required fields)
- [ ] "Place Order" button
- [ ] Order confirmation page
- [ ] Clear cart after order

#### Backend:
- [ ] Create Order model
- [ ] `POST /api/orders` (create order)
- [ ] Save order to database
- [ ] Return order number (ORD-20260917-001)

#### Admin Panel:
- [ ] ⏸️ Still skip (view orders in database directly)

**Goal:** Complete an order, see confirmation, order saved in database.

---

### **Level 5: Admin Panel (Week 9-10)** 👨‍💼

Now build the admin dashboard.

#### Admin Panel:
- [ ] Create React + Vite project
- [ ] Setup Tailwind CSS
- [ ] Login page (simple: hardcoded password for now)
- [ ] Dashboard layout (sidebar + content)
- [ ] **Products page:**
  - [ ] List all products in a table
  - [ ] Add new product form
  - [ ] Edit product (modal or page)
  - [ ] Delete product (with confirmation)
- [ ] **Orders page:**
  - [ ] List all orders
  - [ ] View order details
  - [ ] Update order status (Pending → Confirmed → Shipped → Delivered)

#### Backend:
- [ ] `POST /api/products` (create product)
- [ ] `PUT /api/products/:id` (update product)
- [ ] `DELETE /api/products/:id` (delete product)
- [ ] `GET /api/orders` (list all orders)
- [ ] `PATCH /api/orders/:id` (update status)
- [ ] Add basic auth middleware (check password)

**Goal:** Admin can add/edit/delete products and manage orders from UI.

---

### **Level 6: Bilingual Support (Week 11-12)** 🌐

Add Bengali language support.

#### Storefront:
- [ ] Install `next-intl`
- [ ] Add language switcher (EN/BN button)
- [ ] Translate UI strings (buttons, labels)
- [ ] Support Bengali product names
- [ ] Load Bengali font (Noto Sans Bengali)

#### Backend:
- [ ] Add `nameBn` and `descriptionBn` to Product model

#### Admin Panel:
- [ ] Add Bengali name/description fields in product form

**Goal:** Click language switcher → site changes to Bengali.

---

### **Level 7: Polish & Deploy (Week 13-14)** 🚀

Make it production-ready.

#### All Projects:
- [ ] Mobile responsive design
- [ ] Loading states (spinners)
- [ ] Error handling (try-catch, error pages)
- [ ] Image optimization
- [ ] SEO (meta tags, sitemap)

#### Deployment:
- [ ] Deploy backend to Railway/Render (keep MongoDB Atlas connection)
- [ ] Deploy storefront to Vercel
- [ ] Deploy admin to Vercel/Netlify
- [ ] MongoDB Atlas already in cloud (no migration needed)
- [ ] Environment variables

**Goal:** Live websites anyone can visit!

---

## 🛠️ Tech Stack Details

### 1. Storefront (Customer Site)

```bash
# Create project
npx create-next-app@rc diponty-storefront --typescript --tailwind --app

# Install dependencies
npm install zustand                    # Cart state management
npm install next-intl                  # Bilingual support (Level 6)
npm install axios                      # API calls
```

**Framework:** Next.js 16 (App Router)  
**Styling:** Tailwind CSS with custom brand colors (Mobile-first responsive)  
**State:** Zustand (cart)  
**Language:** TypeScript  
**Design:** Mobile-first responsive design

---

### 2. Admin Panel (Management Dashboard)

```bash
# Create project
npm create vite@latest diponty-admin -- --template react-ts

# Install dependencies
npm install react-router-dom           # Routing
npm install @tanstack/react-query      # Data fetching
npm install @tanstack/react-table      # Tables for product/order lists
npm install axios                      # API calls
npm install tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

**Framework:** React 19 + Vite (pure React, no Next.js)  
**Styling:** Tailwind CSS  
**Routing:** React Router  
**Forms:** React Hook Form (add later when needed)  
**Language:** TypeScript

---

### 3. Backend API (Shared Service)

```bash
# Create project
mkdir diponty-api && cd diponty-api
npm init -y

# Install dependencies
npm install express                    # Web framework
npm install mongoose                   # MongoDB ODM
npm install cors                       # Allow frontend to call API
npm install dotenv                     # Environment variables
npm install bcrypt                     # Password hashing (Level 5)
npm install typescript @types/node @types/express @types/cors @types/bcrypt --save-dev
npm install tsx --save-dev             # Run TypeScript directly
npm install ts-node-dev --save-dev     # Auto-reload during development

# Initialize TypeScript
npx tsc --init
```

**Framework:** Express.js  
**Database:** MongoDB Atlas (Free tier: 512MB storage)  
**ODM:** Mongoose  
**Language:** TypeScript

---

## 📊 Database Schema (Start Simple)

### MongoDB Atlas Free Tier:
- **Storage:** 512MB
- **RAM:** Shared
- **Backup:** Not included (use mongodump manually)
- **Region:** Choose closest to you (e.g., AWS ap-south-1 for India/Bangladesh)
- **Cluster Name:** `diponty-cluster`

### Setup MongoDB Atlas:
1. Go to https://www.mongodb.com/cloud/atlas/register
2. Create free account
3. Create free cluster (M0 tier)
4. Create database user (username + password)
5. Whitelist IP: `0.0.0.0/0` (allow from anywhere - for development)
6. Get connection string: `mongodb+srv://<username>:<password>@diponty-cluster.xxxxx.mongodb.net/diponty?retryWrites=true&w=majority`

---

### Level 1-4 Schema (Mongoose):

```typescript
// src/models/Product.ts

import mongoose, { Schema, Document } from 'mongoose';

export interface IProduct extends Document {
  slug: string;
  name: string;
  price: number;        // in cents/paisa
  images: string[];     // Array of image URLs
  category: string;
  inStock: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const ProductSchema = new Schema<IProduct>(
  {
    slug: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    price: { type: Number, required: true },
    images: [{ type: String }],
    category: { type: String, required: true },
    inStock: { type: Boolean, default: true },
  },
  { timestamps: true }
);

export default mongoose.model<IProduct>('Product', ProductSchema);
```

```typescript
// src/models/Order.ts

import mongoose, { Schema, Document } from 'mongoose';

export interface IOrder extends Document {
  orderNumber: string;
  customerName: string;
  phone: string;
  address: string;      // Simple text for now
  items: any[];         // Array of cart items
  total: number;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}

const OrderSchema = new Schema<IOrder>(
  {
    orderNumber: { type: String, required: true, unique: true },
    customerName: { type: String, required: true },
    phone: { type: String, required: true },
    address: { type: String, required: true },
    items: [{ type: Schema.Types.Mixed }],
    total: { type: Number, required: true },
    status: { type: String, default: 'PENDING' },
  },
  { timestamps: true }
);

export default mongoose.model<IOrder>('Order', OrderSchema);
```

### Level 6+ Schema (Add Bengali):

```typescript
// Updated Product model with Bengali support

export interface IProduct extends Document {
  slug: string;
  name: string;         // English name
  nameBn?: string;      // Bengali name (optional)
  description?: string; // English
  descriptionBn?: string; // Bengali
  price: number;
  images: string[];
  category: string;
  inStock: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const ProductSchema = new Schema<IProduct>(
  {
    slug: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    nameBn: { type: String },
    description: { type: String },
    descriptionBn: { type: String },
    price: { type: Number, required: true },
    images: [{ type: String }],
    category: { type: String, required: true },
    inStock: { type: Boolean, default: true },
  },
  { timestamps: true }
);
```

---

### Database Connection (TypeScript):

```typescript
// src/config/database.ts

import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || '';

export const connectDB = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};
```

```env
# .env file
MONGODB_URI=mongodb+srv://username:password@diponty-cluster.xxxxx.mongodb.net/diponty?retryWrites=true&w=majority
PORT=5000
```

---

## 🎨 Brand Color Examples (Choose Later)

When you're ready, pick ONE of these (or make your own):

### Option 1: Warm & Traditional
```js
brand: {
  primary: '#DC2626',    // Deep red
  secondary: '#F59E0B',  // Amber
  dark: '#1F2937',
  light: '#F9FAFB',
}
```

### Option 2: Modern & Clean
```js
brand: {
  primary: '#3B82F6',    // Blue
  secondary: '#8B5CF6',  // Purple
  dark: '#111827',
  light: '#F3F4F6',
}
```

### Option 3: Elegant & Minimal
```js
brand: {
  primary: '#059669',    // Emerald green
  secondary: '#0891B2',  // Cyan
  dark: '#0F172A',
  light: '#F8FAFC',
}
```

Just paste into `tailwind.config.js` → done! ✨

---

## 📝 File Structure (Level 1 Example)

### Storefront:
```
diponty-storefront/
├── app/
│   ├── page.tsx                 # Homepage
│   ├── layout.tsx               # Root layout
│   └── globals.css              # Tailwind imports
├── components/
│   ├── Header.tsx
│   ├── Footer.tsx
│   └── ProductCard.tsx
├── lib/
│   └── api.ts                   # Fetch functions
├── tailwind.config.js           # 🎨 Brand colors here
└── package.json
```

### Backend:
```
diponty-api/
├── src/
│   ├── index.ts                 # Express server
│   ├── config/
│   │   └── database.ts          # MongoDB connection
│   ├── models/
│   │   ├── Product.ts           # Product model
│   │   └── Order.ts             # Order model
│   ├── routes/
│   │   └── products.ts          # Product routes
│   └── types/
│       └── index.ts             # TypeScript types
├── .env                         # Environment variables
├── tsconfig.json                # TypeScript config
└── package.json
```

---

## ✅ How to Start (Step-by-Step)

### This Weekend: Level 1 Foundation

**Pre-requisite: Setup MongoDB Atlas (15 minutes)**
1. Go to https://www.mongodb.com/cloud/atlas/register
2. Sign up for free account
3. Create a free M0 cluster (512MB)
   - Cloud Provider: AWS
   - Region: Choose closest (e.g., ap-south-1 for India/Bangladesh)
   - Cluster Name: `diponty-cluster`
4. Create database user:
   - Username: `diponty_user`
   - Password: (generate strong password, save it!)
5. Network Access: Add IP `0.0.0.0/0` (allow from anywhere - for learning)
6. Click "Connect" → "Connect your application"
7. Copy connection string (looks like):
   ```
   mongodb+srv://diponty_user:<password>@diponty-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
8. Replace `<password>` with your actual password
9. Save this string - you'll need it!

---

**Day 1: Backend (4-6 hours)**
1. Create `diponty-api` folder
2. Initialize TypeScript Node.js project
3. Install Express + Mongoose + TypeScript
4. Setup MongoDB connection
5. Create Product model (TypeScript interface + schema)
6. Add 5 sample products to MongoDB
7. Create `GET /api/products` route
8. Test in browser: `http://localhost:5000/api/products`

**Day 2: Storefront (4-6 hours)**
1. Create Next.js 16 project with TypeScript
2. Setup Tailwind with temporary brand colors
3. Create mobile-first Header/Footer components
4. Create responsive ProductCard component
5. Fetch products from API using `fetch()` or `axios`
6. Display products in responsive grid (1 col mobile → 2 tablet → 4 desktop)
7. Test on mobile screen size (Chrome DevTools)

**Result:** Working e-commerce skeleton in 2 days! 🎉

---

## 📚 Learning Resources

- **Next.js 16:** https://nextjs.org/docs
- **Tailwind CSS:** https://tailwindcss.com/docs
- **Mobile-first Design:** https://tailwindcss.com/docs/responsive-design
- **MongoDB Atlas:** https://www.mongodb.com/docs/atlas/
- **Mongoose:** https://mongoosejs.com/docs/guide.html
- **Express.js:** https://expressjs.com/
- **TypeScript:** https://www.typescriptlang.org/docs/
- **React Query:** https://tanstack.com/query

---

## 📝 Summary of Changes

✅ **Database:** MongoDB Atlas (free tier, 512MB) instead of Prisma + SQLite  
✅ **All TypeScript:** Storefront, Admin, and Backend all use TypeScript  
✅ **Mobile-first:** All Tailwind classes written mobile-first, scale up with `sm:`, `md:`, `lg:`  
✅ **3 Separate Projects:** Each with own folder, package.json, deployment  
✅ **Brand Colors:** Configured once in `tailwind.config.js`, changes everywhere  
✅ **Learning Path:** 7 levels from basic to production-ready

---

## 🤔 Questions Before Starting?

1. Do you want to start with **Level 1** this weekend?
2. Any specific brand color preferences now, or use placeholder?
3. Should I help you initialize the **backend project first**? (Recommended)

Let me know when you're ready to begin! 🚀
