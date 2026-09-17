# 🎨 Storefront Setup Guide - COOVI

**Project:** coovi-storefront  
**Tech Stack:** Next.js 16 + TypeScript + Tailwind CSS + Zustand

---

## 📋 Prerequisites

- ✅ Node.js 24 installed
- ✅ pnpm installed
- ✅ Backend API running (optional for initial setup)

---

## 🏗️ Step 1: Create Next.js Project

```bash
# Navigate to your projects folder
cd /path/to/coovi-projects

# Create Next.js app with TypeScript
pnpm create next-app@latest coovi-storefront

# When prompted, choose:
✔ Would you like to use TypeScript? › Yes
✔ Would you like to use ESLint? › Yes
✔ Would you like to use Tailwind CSS? › Yes
✔ Would you like to use `src/` directory? › Yes
✔ Would you like to use App Router? › Yes
✔ Would you like to customize the default import alias? › No
```

---

## 📦 Step 2: Install Additional Dependencies

```bash
cd coovi-storefront

# State management & data fetching
pnpm add zustand axios

# UI utilities
pnpm add clsx tailwind-merge

# Type definitions
pnpm add -D @types/node
```

**What each package does:**
- `zustand` → Simple state management for shopping cart
- `axios` → HTTP client for API calls
- `clsx` + `tailwind-merge` → Utility for conditional CSS classes

---

## 🎨 Step 3: Configure Tailwind CSS

### Edit `tailwind.config.ts`:

```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: '#FF6B6B',    // 🎨 Main CTA color - CHANGE THIS
          secondary: '#4ECDC4',  // 🎨 Accent color - CHANGE THIS
          dark: '#1A1A1A',
          light: '#F7F7F7',
        },
        product: {
          card: '#FFFFFF',
          border: '#E5E5E5',
          hover: '#F9F9F9',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      container: {
        center: true,
        padding: {
          DEFAULT: '1rem',
          sm: '2rem',
          lg: '4rem',
          xl: '5rem',
        },
      },
    },
  },
  plugins: [],
};

export default config;
```

---

## 📁 Step 4: Create Folder Structure

```bash
# Create directories
mkdir -p src/components/layout
mkdir -p src/components/product
mkdir -p src/components/cart
mkdir -p src/components/ui
mkdir -p src/lib
mkdir -p src/store
mkdir -p src/types
mkdir -p public/images
```

**Final structure:**
```
coovi-storefront/
├── src/
│   ├── app/                    # Next.js 16 App Router
│   │   ├── layout.tsx
│   │   ├── page.tsx           # Homepage
│   │   ├── products/
│   │   │   └── [slug]/
│   │   │       └── page.tsx   # Product detail
│   │   ├── cart/
│   │   │   └── page.tsx
│   │   ├── checkout/
│   │   │   └── page.tsx
│   │   └── order-confirmation/
│   │       └── [orderNumber]/
│   │           └── page.tsx
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── MobileNav.tsx
│   │   ├── product/
│   │   │   ├── ProductCard.tsx
│   │   │   ├── ProductGrid.tsx
│   │   │   └── ProductDetail.tsx
│   │   ├── cart/
│   │   │   ├── CartButton.tsx
│   │   │   └── CartDrawer.tsx
│   │   └── ui/
│   │       ├── Button.tsx
│   │       └── Input.tsx
│   ├── lib/
│   │   ├── api.ts             # API client
│   │   └── utils.ts           # Utility functions
│   ├── store/
│   │   └── cartStore.ts       # Zustand cart store
│   └── types/
│       └── index.ts           # TypeScript types
├── public/
│   └── images/
├── .env.local
└── package.json
```

---

## 🔐 Step 5: Setup Environment Variables

### Create `.env.local`:

```env
# API Base URL
NEXT_PUBLIC_API_URL=http://localhost:5000/api

# Site Configuration
NEXT_PUBLIC_SITE_NAME=Coovi
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

---

## 📝 Step 6: Create TypeScript Types

### `src/types/index.ts`:

```typescript
export interface Product {
  _id: string;
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
  createdAt: string;
  updatedAt: string;
}

export interface CartItem {
  productId: string;
  slug: string;
  name: string;
  price: number;
  image: string;
  quantity: number;
}

export interface OrderFormData {
  customerName: string;
  phone: string;
  email?: string;
  address: {
    street: string;
    city: string;
    district: string;
    postalCode: string;
  };
  notes?: string;
}

export interface Order {
  _id: string;
  orderNumber: string;
  customerName: string;
  phone: string;
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
  status: string;
  createdAt: string;
}
```

---

## 🛒 Step 7: Create Cart Store (Zustand)

### `src/store/cartStore.ts`:

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { CartItem } from '@/types';

interface CartStore {
  items: CartItem[];
  addItem: (product: CartItem) => void;
  removeItem: (productId: string) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  clearCart: () => void;
  getTotal: () => number;
  getItemCount: () => number;
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],

      addItem: (product) => {
        const items = get().items;
        const existingItem = items.find((item) => item.productId === product.productId);

        if (existingItem) {
          set({
            items: items.map((item) =>
              item.productId === product.productId
                ? { ...item, quantity: item.quantity + 1 }
                : item
            ),
          });
        } else {
          set({ items: [...items, { ...product, quantity: 1 }] });
        }
      },

      removeItem: (productId) => {
        set({ items: get().items.filter((item) => item.productId !== productId) });
      },

      updateQuantity: (productId, quantity) => {
        if (quantity <= 0) {
          get().removeItem(productId);
          return;
        }

        set({
          items: get().items.map((item) =>
            item.productId === productId ? { ...item, quantity } : item
          ),
        });
      },

      clearCart: () => {
        set({ items: [] });
      },

      getTotal: () => {
        return get().items.reduce((total, item) => total + item.price * item.quantity, 0);
      },

      getItemCount: () => {
        return get().items.reduce((count, item) => count + item.quantity, 0);
      },
    }),
    {
      name: 'coovi-cart',
    }
  )
);
```

---

## 🌐 Step 8: Create API Client

### `src/lib/api.ts`:

```typescript
import axios from 'axios';
import { Product, Order, OrderFormData } from '@/types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Products API
export const productsApi = {
  getAll: async (params?: {
    page?: number;
    limit?: number;
    search?: string;
    sort?: string;
  }) => {
    const { data } = await api.get<{ products: Product[]; total: number }>('/products', {
      params,
    });
    return data;
  },

  getBySlug: async (slug: string) => {
    const { data } = await api.get<{ product: Product }>(`/products/${slug}`);
    return data.product;
  },

  getFeatured: async () => {
    const { data } = await api.get<{ products: Product[] }>('/products?featured=true');
    return data.products;
  },
};

// Orders API
export const ordersApi = {
  create: async (orderData: OrderFormData & { items: any[] }) => {
    const { data } = await api.post<{ order: Order }>('/orders', orderData);
    return data.order;
  },

  getByOrderNumber: async (orderNumber: string) => {
    const { data } = await api.get<{ order: Order }>(`/orders/${orderNumber}`);
    return data.order;
  },
};

export default api;
```

---

## 🛠️ Step 9: Create Utility Functions

### `src/lib/utils.ts`:

```typescript
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

// Merge Tailwind classes
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Format price
export function formatPrice(price: number): string {
  return `৳${price.toLocaleString()}`;
}

// Generate slug from text
export function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
```

---

## 🎨 Step 10: Update Root Layout

### `src/app/layout.tsx`:

```typescript
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Coovi - Premium Sarees Online',
  description: 'Shop beautiful sarees at Coovi',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  );
}
```

---

## 📜 Step 11: Update package.json Scripts

Your `package.json` should have:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  }
}
```

---

## ✅ Step 12: Test the Setup

```bash
# Run development server
pnpm dev
```

**Expected output:**
```
▲ Next.js 16.0.0
- Local:        http://localhost:3000
- Ready in 2.1s
```

### Test in browser:

Visit: `http://localhost:3000`

You should see the default Next.js welcome page.

---

## 🎯 Next Steps

After basic setup works:

1. ✅ Next.js running on port 3000
2. ⏭️ Create Header/Footer components
3. ⏭️ Create ProductCard component
4. ⏭️ Build Homepage with product grid
5. ⏭️ Connect to backend API
6. ⏭️ Test cart functionality

---

## 🐛 Common Issues & Solutions

### Issue: Port 3000 already in use
```bash
# Change port
pnpm dev -- -p 3001
```

### Issue: Environment variables not loading
```bash
# Restart dev server after creating .env.local
# Variables must start with NEXT_PUBLIC_ to be accessible in browser
```

---

**Storefront foundation ready! Next: Build components** 🎉
