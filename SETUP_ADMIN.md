# 👨‍💼 Admin Panel Setup Guide - COOVI

**Project:** coovi-admin  
**Tech Stack:** React 19 + Vite + TypeScript + Material UI + React Router

---

## 📋 Prerequisites

- ✅ Node.js 24 installed
- ✅ pnpm installed
- ✅ Backend API running (optional for initial setup)

---

## 🏗️ Step 1: Create Vite + React Project

```bash
# Navigate to your projects folder
cd /path/to/coovi-projects

# Create Vite app with React + TypeScript
pnpm create vite coovi-admin --template react-ts

cd coovi-admin
```

---

## 📦 Step 2: Install Dependencies

```bash
# Material UI (complete package)
pnpm add @mui/material @emotion/react @emotion/styled

# Material UI Icons
pnpm add @mui/icons-material

# Routing
pnpm add react-router-dom

# Data fetching & state
pnpm add @tanstack/react-query axios

# Form handling
pnpm add react-hook-form

# Date utilities (for MUI DatePicker if needed later)
pnpm add @mui/x-date-pickers dayjs

# Dev dependencies
pnpm add -D @types/react-router-dom
```

**What each package does:**
- `@mui/material` → Material UI components
- `@mui/icons-material` → Material Design icons
- `react-router-dom` → Client-side routing
- `@tanstack/react-query` → Server state management & caching
- `axios` → HTTP client for API calls
- `react-hook-form` → Form validation & handling

---

## 📁 Step 3: Create Folder Structure

```bash
# Create directories
mkdir -p src/components/layout
mkdir -p src/components/products
mkdir -p src/components/orders
mkdir -p src/pages
mkdir -p src/api
mkdir -p src/types
mkdir -p src/store
mkdir -p src/utils
mkdir -p src/theme
```

**Final structure:**
```
coovi-admin/
├── src/
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Topbar.tsx
│   │   │   └── DashboardLayout.tsx
│   │   ├── products/
│   │   │   ├── ProductTable.tsx
│   │   │   ├── ProductForm.tsx
│   │   │   └── ProductCard.tsx
│   │   └── orders/
│   │       ├── OrderTable.tsx
│   │       ├── OrderDetail.tsx
│   │       └── StatusChip.tsx
│   ├── pages/
│   │   ├── LoginPage.tsx
│   │   ├── DashboardPage.tsx
│   │   ├── ProductsPage.tsx
│   │   ├── ProductFormPage.tsx
│   │   ├── OrdersPage.tsx
│   │   └── OrderDetailPage.tsx
│   ├── api/
│   │   ├── client.ts          # Axios config
│   │   ├── products.ts        # Product API calls
│   │   ├── orders.ts          # Order API calls
│   │   └── auth.ts            # Auth API calls
│   ├── types/
│   │   └── index.ts           # TypeScript types
│   ├── store/
│   │   └── authStore.ts       # Auth state (Zustand or Context)
│   ├── utils/
│   │   └── helpers.ts         # Utility functions
│   ├── theme/
│   │   └── theme.ts           # MUI theme config
│   ├── App.tsx
│   ├── main.tsx
│   └── vite-env.d.ts
├── .env
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

---

## 🔐 Step 4: Setup Environment Variables

### Create `.env`:

```env
# API Base URL
VITE_API_URL=http://localhost:5000/api

# App Configuration
VITE_APP_NAME=Coovi Admin
```

---

## 📝 Step 5: Create TypeScript Types

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

export interface Order {
  _id: string;
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
  items: OrderItem[];
  subtotal: number;
  deliveryFee: number;
  total: number;
  paymentMethod: 'COD';
  status: OrderStatus;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface OrderItem {
  productId: string;
  name: string;
  price: number;
  quantity: number;
  image: string;
}

export type OrderStatus = 'Pending' | 'Processing' | 'Shipped' | 'Delivered' | 'Cancelled';

export interface Admin {
  _id: string;
  email: string;
  name: string;
  role: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  admin: Admin;
}

export interface DashboardStats {
  totalOrders: number;
  pendingOrders: number;
  totalRevenue: number;
  lowStockProducts: number;
}
```

---

## 🌐 Step 6: Create API Client

### `src/api/client.ts`:

```typescript
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests if available
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401 errors (token expired)
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### `src/api/auth.ts`:

```typescript
import apiClient from './client';
import { LoginCredentials, AuthResponse, Admin } from '@/types';

export const authApi = {
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const { data } = await apiClient.post('/auth/login', credentials);
    return data;
  },

  logout: async (): Promise<void> => {
    await apiClient.post('/auth/logout');
    localStorage.removeItem('admin_token');
  },

  getCurrentAdmin: async (): Promise<Admin> => {
    const { data } = await apiClient.get('/auth/me');
    return data.admin;
  },
};
```

### `src/api/products.ts`:

```typescript
import apiClient from './client';
import { Product } from '@/types';

export const productsApi = {
  getAll: async (params?: { page?: number; limit?: number; search?: string }) => {
    const { data } = await apiClient.get('/products', { params });
    return data;
  },

  getById: async (id: string): Promise<Product> => {
    const { data } = await apiClient.get(`/products/${id}`);
    return data.product;
  },

  create: async (productData: Partial<Product>): Promise<Product> => {
    const { data } = await apiClient.post('/products', productData);
    return data.product;
  },

  update: async (id: string, productData: Partial<Product>): Promise<Product> => {
    const { data } = await apiClient.put(`/products/${id}`, productData);
    return data.product;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/products/${id}`);
  },
};
```

### `src/api/orders.ts`:

```typescript
import apiClient from './client';
import { Order, OrderStatus } from '@/types';

export const ordersApi = {
  getAll: async (params?: { page?: number; limit?: number; status?: string }) => {
    const { data } = await apiClient.get('/orders', { params });
    return data;
  },

  getById: async (id: string): Promise<Order> => {
    const { data } = await apiClient.get(`/orders/${id}`);
    return data.order;
  },

  updateStatus: async (id: string, status: OrderStatus): Promise<Order> => {
    const { data } = await apiClient.patch(`/orders/${id}/status`, { status });
    return data.order;
  },
};
```

---

## 🎨 Step 7: Create MUI Theme

### `src/theme/theme.ts`:

```typescript
import { createTheme } from '@mui/material/styles';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2', // Blue
      light: '#42a5f5',
      dark: '#1565c0',
    },
    secondary: {
      main: '#dc004e', // Pink/Red
      light: '#f50057',
      dark: '#c51162',
    },
    success: {
      main: '#4caf50',
    },
    warning: {
      main: '#ff9800',
    },
    error: {
      main: '#f44336',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 600,
    },
    h5: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none', // Disable uppercase
          fontWeight: 500,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        },
      },
    },
  },
});

export default theme;
```

---

## 🛠️ Step 8: Setup React Query

### `src/main.tsx`:

```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import App from './App';
import theme from './theme/theme';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <App />
        </ThemeProvider>
      </QueryClientProvider>
    </BrowserRouter>
  </React.StrictMode>
);
```

---

## 🗺️ Step 9: Setup React Router

### `src/App.tsx`:

```typescript
import { Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ProductsPage from './pages/ProductsPage';
import OrdersPage from './pages/OrdersPage';
import DashboardLayout from './components/layout/DashboardLayout';

// Protected Route wrapper
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const token = localStorage.getItem('admin_token');
  
  if (!token) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
}

function App() {
  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/login" element={<LoginPage />} />

      {/* Protected Routes */}
      <Route
        path="/*"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <Routes>
                <Route path="/" element={<Navigate to="/dashboard" replace />} />
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/products" element={<ProductsPage />} />
                <Route path="/orders" element={<OrdersPage />} />
              </Routes>
            </DashboardLayout>
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}

export default App;
```

---

## 🛠️ Step 10: Update Vite Config

### `vite.config.ts`:

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
  },
});
```

### Update `tsconfig.json` (add path alias):

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

---

## 📜 Step 11: Update package.json Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0"
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
VITE v5.0.0  ready in 500 ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
```

### Test in browser:

Visit: `http://localhost:5173`

You should see a blank page (we haven't created components yet).

---

## 🎯 Next Steps

After basic setup works:

1. ✅ React + Vite running on port 5173
2. ✅ Material UI installed and themed
3. ✅ React Router configured
4. ⏭️ Create Login page
5. ⏭️ Create Dashboard layout (Sidebar + Topbar)
6. ⏭️ Create Product and Order tables
7. ⏭️ Connect to backend API

---

## 🐛 Common Issues & Solutions

### Issue: Port 5173 already in use
```bash
# Change port in vite.config.ts
server: { port: 5174 }
```

### Issue: Path alias @ not working
```bash
# Make sure both vite.config.ts and tsconfig.json have path alias configured
# Restart dev server after config changes
```

### Issue: MUI styles not loading
```bash
# Make sure CssBaseline is included in main.tsx
# Check ThemeProvider wraps entire app
```

---

**Admin panel foundation ready! Next: Build UI components** 🎉
