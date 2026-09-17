# 🏗️ COOVI E-Commerce - Complete Architecture

**Brand:** Coovi  
**Product:** Saree E-commerce Platform  
**Purpose:** Learning project → Production launch

---

## 📦 Project Structure

```
coovi-projects/                     # Root folder (you'll decide location at home)
├── coovi-storefront/               # Customer-facing Next.js app
├── coovi-admin/                    # Admin dashboard (React + Vite + MUI)
└── coovi-api/                      # Backend API (Express + MongoDB)
```

---

## 🎨 Tech Stack Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Storefront** | Next.js 16 + TypeScript | Customer shopping experience |
| **Styling** | Tailwind CSS | Mobile-first responsive design |
| **Admin Panel** | React 19 + Vite + TypeScript | Product/order management |
| **Admin UI** | Material UI (MUI) | Professional admin components |
| **Backend** | Express.js + TypeScript | REST API server |
| **Database** | MongoDB Atlas (Free M0) | Product/order storage |
| **ODM** | Mongoose | MongoDB object modeling |
| **Images** | Cloudinary (Free tier) | Image hosting/optimization |
| **State** | Zustand | Shopping cart state |
| **Routing** | React Router v6 | Admin panel routing |
| **Runtime** | Node.js 24 | Server runtime |
| **Package Manager** | pnpm | Fast, efficient installs |
| **Deployment** | Vercel (storefront + admin) | Free hosting |
| **API Hosting** | Railway/Render | Backend hosting |

---

## 🗄️ Database Schema

### Product Collection

```typescript
{
  _id: ObjectId,
  slug: string,              // URL-friendly: "red-cotton-saree"
  name: string,              // "Red Cotton Saree"
  price: number,             // 1299 (BDT, whole number)
  images: string[],          // ["url1", "url2"] - Cloudinary URLs
  category: string,          // "Saree" (all products for now)
  size?: string,             // Optional: "Free Size", "M", "L" (future)
  description?: string,      // Product description
  inStock: boolean,          // true/false
  stockCount: number,        // 10, 5, 0
  featured: boolean,         // Show in homepage featured section
  createdAt: Date,
  updatedAt: Date
}
```

### Order Collection

```typescript
{
  _id: ObjectId,
  orderNumber: string,       // "ORD-20260917-001"
  customerName: string,
  phone: string,
  email?: string,            // Optional
  address: {
    street: string,
    city: string,
    district: string,
    postalCode: string
  },
  items: [
    {
      productId: ObjectId,   // Reference to Product
      name: string,          // Product name at order time
      price: number,         // Price at order time
      quantity: number,
      image: string          // Primary image URL
    }
  ],
  subtotal: number,          // Sum of items
  deliveryFee: number,       // From .env config
  total: number,             // subtotal + deliveryFee
  paymentMethod: "COD",      // Cash on Delivery
  status: "Pending" | "Processing" | "Shipped" | "Delivered" | "Cancelled",
  notes?: string,            // Customer order notes
  createdAt: Date,
  updatedAt: Date
}
```

### Admin Collection

```typescript
{
  _id: ObjectId,
  email: string,             // admin@coovi.com
  password: string,          // bcrypt hashed
  name: string,              // Admin name
  role: "admin",             // Future: "super_admin", "manager"
  createdAt: Date
}
```

---

## 🔌 API Endpoints

**Base URL (Dev):** `http://localhost:5000/api`  
**Base URL (Prod):** `https://api.coovi.com/api` (or Railway/Render URL)

### Products

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/products` | List products (pagination, search, sort) | Public |
| GET | `/products/:slug` | Single product by slug | Public |
| POST | `/products` | Create product | Admin |
| PUT | `/products/:id` | Update product | Admin |
| DELETE | `/products/:id` | Delete product | Admin |

**Query params for GET `/products`:**
- `page` (number): Page number (default: 1)
- `limit` (number): Products per page (default: 12)
- `search` (string): Search by name (partial match)
- `sort` (string): "price_asc" | "price_desc" | "newest"
- `category` (string): Filter by category (future)

### Orders

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/orders` | Create order (checkout) | Public |
| GET | `/orders` | List all orders | Admin |
| GET | `/orders/:id` | Single order details | Admin |
| PATCH | `/orders/:id/status` | Update order status | Admin |

### Admin Auth

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/login` | Admin login | Public |
| POST | `/auth/logout` | Admin logout | Admin |
| GET | `/auth/me` | Get current admin | Admin |

---

## 🎨 Storefront Pages

| Route | Page | Description |
|-------|------|-------------|
| `/` | Homepage | Hero, featured products, all products grid |
| `/products` | All Products | Infinite scroll product list |
| `/products/:slug` | Product Detail | Single product page |
| `/cart` | Shopping Cart | Cart items, update quantity |
| `/checkout` | Checkout | Order form (COD) |
| `/order-confirmation/:orderNumber` | Confirmation | Order success page |

---

## 👨‍💼 Admin Panel Pages

| Route | Page | Description |
|-------|------|-------------|
| `/login` | Login | Admin authentication |
| `/dashboard` | Dashboard | Overview stats |
| `/dashboard/products` | Products List | Product table with actions |
| `/dashboard/products/new` | Add Product | Create product form |
| `/dashboard/products/:id/edit` | Edit Product | Update product form |
| `/dashboard/orders` | Orders List | Order table with filters |
| `/dashboard/orders/:id` | Order Detail | View order, update status |

---

## 🎨 Design System - Tailwind Config

### Brand Colors (Configurable)

```js
// tailwind.config.js
colors: {
  brand: {
    primary: '#FF6B6B',    // 🎨 CHANGE THIS - Main CTA color
    secondary: '#4ECDC4',  // 🎨 CHANGE THIS - Accent color
    dark: '#1A1A1A',       // Dark text
    light: '#F7F7F7',      // Light background
  },
  product: {
    card: '#FFFFFF',
    border: '#E5E5E5',
    hover: '#F9F9F9',
  },
}
```

### Mobile-First Breakpoints

```js
screens: {
  'sm': '640px',   // Tablet
  'md': '768px',   // Desktop
  'lg': '1024px',  // Large desktop
  'xl': '1280px',  // Extra large
}
```

---

## 🚀 Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
         ▼             ▼             ▼
    ┌────────┐   ┌─────────┐   ┌────────┐
    │ Vercel │   │ Vercel  │   │Railway │
    │Storefront  │  Admin  │   │  API   │
    └────────┘   └─────────┘   └───┬────┘
         │             │            │
         └─────────────┴────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ MongoDB Atlas   │
              │  (Free Tier)    │
              └─────────────────┘
```

**URLs (Production):**
- Storefront: `https://coovi.vercel.app`
- Admin: `https://coovi-admin.vercel.app`
- API: `https://coovi-api.railway.app`

---

## 🌍 Environment Variables

### Backend (.env)

```env
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb+srv://username:password@coovi-cluster.xxxxx.mongodb.net/coovi
JWT_SECRET=your_super_secret_key_change_this
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
DELIVERY_FEE=60
```

### Storefront (.env.local)

```env
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

### Admin (.env)

```env
VITE_API_URL=http://localhost:5000/api
```

---

## 🎓 What You'll Learn

✅ **Frontend:** Next.js 16 App Router, Server Components, React 19  
✅ **Styling:** Tailwind CSS mobile-first, responsive design  
✅ **State Management:** Zustand (cart), React Query (server state)  
✅ **Backend:** Express REST API, middleware, error handling  
✅ **Database:** MongoDB, Mongoose ODM, schema design  
✅ **Authentication:** JWT, bcrypt, protected routes  
✅ **Images:** Cloudinary upload, optimization  
✅ **Deployment:** Vercel (frontend), Railway/Render (backend)  
✅ **TypeScript:** Full-stack type safety  

---

**Ready to build Coovi! 🎉**
