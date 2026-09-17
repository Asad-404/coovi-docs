# 📊 Database Models Reference - COOVI

Complete MongoDB schemas with TypeScript interfaces and Mongoose models.

---

## 🗄️ Product Model

### TypeScript Interface

```typescript
export interface IProduct extends Document {
  slug: string;              // URL-friendly: "red-cotton-saree"
  name: string;              // Display name
  price: number;             // In BDT (whole number)
  images: string[];          // Cloudinary URLs
  category: string;          // "Saree" (future: multiple categories)
  size?: string;             // Optional: "Free Size", "M", "L"
  description?: string;      // Product description
  inStock: boolean;          // Availability flag
  stockCount: number;        // Inventory count
  featured: boolean;         // Show on homepage
  createdAt: Date;
  updatedAt: Date;
}
```

### Mongoose Schema

```typescript
import mongoose, { Schema } from 'mongoose';

const ProductSchema = new Schema(
  {
    slug: {
      type: String,
      required: [true, 'Product slug is required'],
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Product name is required'],
      trim: true,
    },
    price: {
      type: Number,
      required: [true, 'Product price is required'],
      min: [0, 'Price cannot be negative'],
    },
    images: {
      type: [String],
      required: [true, 'At least one image is required'],
      validate: {
        validator: (v: string[]) => v.length > 0,
        message: 'Product must have at least one image',
      },
    },
    category: {
      type: String,
      required: true,
      default: 'Saree',
      index: true,
    },
    size: {
      type: String,
      required: false,
    },
    description: {
      type: String,
      trim: true,
    },
    inStock: {
      type: Boolean,
      default: true,
    },
    stockCount: {
      type: Number,
      required: true,
      min: [0, 'Stock cannot be negative'],
      default: 0,
    },
    featured: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Text search index for name
ProductSchema.index({ name: 'text' });

export default mongoose.model('Product', ProductSchema);
```

### Example Document

```json
{
  "_id": "65a1b2c3d4e5f6789012345",
  "slug": "red-cotton-saree",
  "name": "Red Cotton Saree",
  "price": 1299,
  "images": [
    "https://res.cloudinary.com/coovi/image/upload/v1/products/red-cotton-1.jpg",
    "https://res.cloudinary.com/coovi/image/upload/v1/products/red-cotton-2.jpg"
  ],
  "category": "Saree",
  "size": "Free Size",
  "description": "Beautiful red cotton saree with traditional border design",
  "inStock": true,
  "stockCount": 15,
  "featured": true,
  "createdAt": "2026-09-17T10:00:00.000Z",
  "updatedAt": "2026-09-17T10:00:00.000Z"
}
```

---

## 📦 Order Model

### TypeScript Interface

```typescript
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
  createdAt: Date;
  updatedAt: Date;
}
```

### Mongoose Schema

```typescript
import mongoose, { Schema } from 'mongoose';

const OrderSchema = new Schema(
  {
    orderNumber: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    customerName: {
      type: String,
      required: [true, 'Customer name is required'],
      trim: true,
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
    },
    address: {
      street: { type: String, required: true },
      city: { type: String, required: true },
      district: { type: String, required: true },
      postalCode: { type: String, required: true },
    },
    items: [
      {
        productId: { type: String, required: true },
        name: { type: String, required: true },
        price: { type: Number, required: true },
        quantity: { type: Number, required: true, min: 1 },
        image: { type: String, required: true },
      },
    ],
    subtotal: {
      type: Number,
      required: true,
      min: 0,
    },
    deliveryFee: {
      type: Number,
      required: true,
      min: 0,
    },
    total: {
      type: Number,
      required: true,
      min: 0,
    },
    paymentMethod: {
      type: String,
      enum: ['COD'],
      default: 'COD',
    },
    status: {
      type: String,
      enum: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'],
      default: 'Pending',
      index: true,
    },
    notes: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for sorting by newest
OrderSchema.index({ createdAt: -1 });

export default mongoose.model('Order', OrderSchema);
```

### Example Document

```json
{
  "_id": "65a1b2c3d4e5f6789012346",
  "orderNumber": "ORD-20260917-001",
  "customerName": "John Doe",
  "phone": "+8801712345678",
  "email": "john@example.com",
  "address": {
    "street": "123 Main Street",
    "city": "Dhaka",
    "district": "Dhaka",
    "postalCode": "1200"
  },
  "items": [
    {
      "productId": "65a1b2c3d4e5f6789012345",
      "name": "Red Cotton Saree",
      "price": 1299,
      "quantity": 2,
      "image": "https://res.cloudinary.com/coovi/image/upload/v1/products/red-cotton-1.jpg"
    }
  ],
  "subtotal": 2598,
  "deliveryFee": 60,
  "total": 2658,
  "paymentMethod": "COD",
  "status": "Pending",
  "notes": "Please deliver after 5 PM",
  "createdAt": "2026-09-17T14:30:00.000Z",
  "updatedAt": "2026-09-17T14:30:00.000Z"
}
```

---

## 👤 Admin Model

### TypeScript Interface

```typescript
export interface IAdmin extends Document {
  email: string;
  password: string;
  name: string;
  role: 'admin' | 'super_admin' | 'manager';
  createdAt: Date;
  updatedAt: Date;
  comparePassword(candidatePassword: string): Promise<boolean>;
}
```

### Mongoose Schema

```typescript
import mongoose, { Schema } from 'mongoose';
import bcrypt from 'bcrypt';

const AdminSchema = new Schema(
  {
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false,
    },
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    role: {
      type: String,
      enum: ['admin', 'super_admin', 'manager'],
      default: 'admin',
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
AdminSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Method to compare passwords
AdminSchema.methods.comparePassword = async function (
  candidatePassword: string
): Promise<boolean> {
  return await bcrypt.compare(candidatePassword, this.password);
};

export default mongoose.model('Admin', AdminSchema);
```

### Example Document

```json
{
  "_id": "65a1b2c3d4e5f6789012347",
  "email": "admin@coovi.com",
  "password": "$2b$10$abcdefghijklmnopqrstuvwxyz123456789", // Hashed
  "name": "Admin User",
  "role": "admin",
  "createdAt": "2026-09-17T10:00:00.000Z",
  "updatedAt": "2026-09-17T10:00:00.000Z"
}
```

---

## 🔑 Order Number Generation

### Helper Function

```typescript
// src/utils/orderNumber.ts
export const generateOrderNumber = async (): Promise<string> => {
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, ''); // YYYYMMDD
  
  // Find today's order count
  const todayStart = new Date(today.setHours(0, 0, 0, 0));
  const todayEnd = new Date(today.setHours(23, 59, 59, 999));
  
  const count = await Order.countDocuments({
    createdAt: { $gte: todayStart, $lte: todayEnd },
  });
  
  const orderNum = (count + 1).toString().padStart(3, '0');
  
  return `ORD-${dateStr}-${orderNum}`;
};

// Usage in order controller:
// const orderNumber = await generateOrderNumber();
// Result: "ORD-20260917-001"
```

---

## 📈 Common Queries

### Products

```typescript
// Get all in-stock products
const products = await Product.find({ inStock: true });

// Get featured products
const featured = await Product.find({ featured: true }).limit(8);

// Search by name (case-insensitive, partial match)
const results = await Product.find({
  name: { $regex: searchTerm, $options: 'i' }
});

// Sort by price
const sorted = await Product.find().sort({ price: 1 }); // Ascending
const sorted = await Product.find().sort({ price: -1 }); // Descending

// Pagination
const page = 1;
const limit = 12;
const products = await Product.find()
  .skip((page - 1) * limit)
  .limit(limit);

// Get low stock products
const lowStock = await Product.find({ stockCount: { $lt: 5 } });
```

### Orders

```typescript
// Get all pending orders
const pending = await Order.find({ status: 'Pending' }).sort({ createdAt: -1 });

// Get orders by date range
const startDate = new Date('2026-09-01');
const endDate = new Date('2026-09-30');
const orders = await Order.find({
  createdAt: { $gte: startDate, $lte: endDate }
});

// Get total revenue
const revenue = await Order.aggregate([
  { $match: { status: { $ne: 'Cancelled' } } },
  { $group: { _id: null, total: { $sum: '$total' } } }
]);

// Get customer's order history
const customerOrders = await Order.find({ phone: '+8801712345678' });
```

---

## 🔄 Stock Management

### Decrease Stock on Order Confirmation

```typescript
// In order controller when status changes to "Confirmed"
for (const item of order.items) {
  await Product.findByIdAndUpdate(
    item.productId,
    {
      $inc: { stockCount: -item.quantity },
      $set: { inStock: false } // Set to false if stockCount becomes 0
    }
  );
}

// Better: Check if stock is sufficient first
for (const item of order.items) {
  const product = await Product.findById(item.productId);
  
  if (!product || product.stockCount < item.quantity) {
    throw new Error(`Insufficient stock for ${item.name}`);
  }
  
  product.stockCount -= item.quantity;
  product.inStock = product.stockCount > 0;
  await product.save();
}
```

---

## 📊 Dashboard Stats Aggregation

```typescript
export const getDashboardStats = async () => {
  // Total orders today
  const todayStart = new Date(new Date().setHours(0, 0, 0, 0));
  const todayOrders = await Order.countDocuments({
    createdAt: { $gte: todayStart }
  });

  // Pending orders
  const pendingOrders = await Order.countDocuments({ status: 'Pending' });

  // Total revenue (all time, excluding cancelled)
  const revenueResult = await Order.aggregate([
    { $match: { status: { $ne: 'Cancelled' } } },
    { $group: { _id: null, total: { $sum: '$total' } } }
  ]);
  const totalRevenue = revenueResult[0]?.total || 0;

  // Low stock products
  const lowStockCount = await Product.countDocuments({ stockCount: { $lt: 5 } });

  return {
    todayOrders,
    pendingOrders,
    totalRevenue,
    lowStockCount
  };
};
```

---

## 🔍 Indexes for Performance

```typescript
// Product indexes (already in schema)
ProductSchema.index({ slug: 1 });
ProductSchema.index({ category: 1 });
ProductSchema.index({ featured: 1 });
ProductSchema.index({ name: 'text' });

// Order indexes (already in schema)
OrderSchema.index({ orderNumber: 1 });
OrderSchema.index({ status: 1 });
OrderSchema.index({ createdAt: -1 });

// Compound index for common queries
OrderSchema.index({ status: 1, createdAt: -1 });
ProductSchema.index({ category: 1, featured: 1 });
```

---

**Database models complete! Ready for implementation** 🎉
