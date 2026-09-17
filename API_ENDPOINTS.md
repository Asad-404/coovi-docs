# 🔌 API Endpoints Documentation - COOVI

Complete REST API reference for all backend endpoints.

---

## 🌐 Base URL

**Development:** `http://localhost:5000/api`  
**Production:** `https://your-api-domain.com/api`

---

## 🔐 Authentication

All admin routes require JWT token in Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

---

## 📦 Products API

### GET /products

Get paginated list of products with search and sort.

**Query Parameters:**
- `page` (number, optional) - Page number, default: 1
- `limit` (number, optional) - Items per page, default: 12
- `search` (string, optional) - Search by product name
- `sort` (string, optional) - Sort order: `price_asc`, `price_desc`, `newest`
- `featured` (boolean, optional) - Filter featured products
- `category` (string, optional) - Filter by category

**Response:**
```json
{
  "success": true,
  "products": [
    {
      "_id": "65a1b2c3d4e5f6789012345",
      "slug": "red-cotton-saree",
      "name": "Red Cotton Saree",
      "price": 1299,
      "images": ["url1", "url2"],
      "category": "Saree",
      "inStock": true,
      "stockCount": 15,
      "featured": true,
      "createdAt": "2026-09-17T10:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 50,
    "page": 1,
    "pages": 5,
    "limit": 12
  }
}
```

**Example Requests:**
```bash
# Get all products
GET /api/products

# Search products
GET /api/products?search=red

# Featured products only
GET /api/products?featured=true

# Sorted by price (low to high)
GET /api/products?sort=price_asc

# Pagination
GET /api/products?page=2&limit=20
```

---

### GET /products/:slug

Get single product by slug.

**Parameters:**
- `slug` (string) - Product slug (e.g., "red-cotton-saree")

**Response:**
```json
{
  "success": true,
  "product": {
    "_id": "65a1b2c3d4e5f6789012345",
    "slug": "red-cotton-saree",
    "name": "Red Cotton Saree",
    "price": 1299,
    "images": ["url1", "url2"],
    "category": "Saree",
    "size": "Free Size",
    "description": "Beautiful red cotton saree",
    "inStock": true,
    "stockCount": 15,
    "featured": true,
    "createdAt": "2026-09-17T10:00:00.000Z",
    "updatedAt": "2026-09-17T10:00:00.000Z"
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Product not found"
}
```

---

### POST /products 🔒

Create new product (Admin only).

**Headers:**
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "Blue Silk Saree",
  "slug": "blue-silk-saree",
  "price": 2499,
  "images": [
    "https://res.cloudinary.com/coovi/image/upload/v1/products/blue-1.jpg",
    "https://res.cloudinary.com/coovi/image/upload/v1/products/blue-2.jpg"
  ],
  "category": "Saree",
  "size": "Free Size",
  "description": "Elegant blue silk saree",
  "stockCount": 10,
  "featured": false
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Product created successfully",
  "product": { /* product object */ }
}
```

**Validation Errors (400):**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "name": "Product name is required",
    "price": "Price must be greater than 0"
  }
}
```

---

### PUT /products/:id 🔒

Update existing product (Admin only).

**Parameters:**
- `id` (string) - Product MongoDB _id

**Request Body:**
```json
{
  "name": "Updated Product Name",
  "price": 1499,
  "stockCount": 20,
  "featured": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Product updated successfully",
  "product": { /* updated product */ }
}
```

---

### DELETE /products/:id 🔒

Delete product (Admin only).

**Parameters:**
- `id` (string) - Product MongoDB _id

**Response:**
```json
{
  "success": true,
  "message": "Product deleted successfully"
}
```

---

## 📦 Orders API

### POST /orders

Create new order (Guest checkout).

**Request Body:**
```json
{
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
      "image": "https://cloudinary.com/image.jpg"
    }
  ],
  "notes": "Please deliver after 5 PM"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Order placed successfully",
  "order": {
    "_id": "65a1b2c3d4e5f6789012346",
    "orderNumber": "ORD-20260917-001",
    "customerName": "John Doe",
    "phone": "+8801712345678",
    "items": [/* items */],
    "subtotal": 2598,
    "deliveryFee": 60,
    "total": 2658,
    "status": "Pending",
    "createdAt": "2026-09-17T14:30:00.000Z"
  }
}
```

**Validation Errors:**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "customerName": "Customer name is required",
    "phone": "Phone number is required",
    "items": "At least one item is required"
  }
}
```

**Stock Error (400):**
```json
{
  "success": false,
  "message": "Product 'Red Cotton Saree' is out of stock"
}
```

---

### GET /orders 🔒

Get all orders (Admin only).

**Query Parameters:**
- `page` (number) - Page number
- `limit` (number) - Items per page
- `status` (string) - Filter by status: `Pending`, `Processing`, `Shipped`, `Delivered`, `Cancelled`
- `search` (string) - Search by order number or customer name

**Response:**
```json
{
  "success": true,
  "orders": [
    {
      "_id": "65a1b2c3d4e5f6789012346",
      "orderNumber": "ORD-20260917-001",
      "customerName": "John Doe",
      "phone": "+8801712345678",
      "total": 2658,
      "status": "Pending",
      "createdAt": "2026-09-17T14:30:00.000Z"
    }
  ],
  "pagination": {
    "total": 100,
    "page": 1,
    "pages": 10,
    "limit": 10
  }
}
```

---

### GET /orders/:id 🔒

Get single order details (Admin only).

**Parameters:**
- `id` (string) - Order MongoDB _id or order number

**Response:**
```json
{
  "success": true,
  "order": {
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
        "image": "url"
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
}
```

---

### PATCH /orders/:id/status 🔒

Update order status (Admin only).

**Parameters:**
- `id` (string) - Order MongoDB _id

**Request Body:**
```json
{
  "status": "Processing"
}
```

**Allowed Status Values:**
- `Pending`
- `Processing`
- `Shipped`
- `Delivered`
- `Cancelled`

**Response:**
```json
{
  "success": true,
  "message": "Order status updated to Processing",
  "order": { /* updated order */ }
}
```

**Note:** When status changes to `Processing`, stock is decreased automatically.

---

## 🔐 Authentication API

### POST /auth/login

Admin login.

**Request Body:**
```json
{
  "email": "admin@coovi.com",
  "password": "your_password"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "admin": {
    "_id": "65a1b2c3d4e5f6789012347",
    "email": "admin@coovi.com",
    "name": "Admin User",
    "role": "admin"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

---

### POST /auth/logout 🔒

Admin logout.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### GET /auth/me 🔒

Get current admin details.

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "admin": {
    "_id": "65a1b2c3d4e5f6789012347",
    "email": "admin@coovi.com",
    "name": "Admin User",
    "role": "admin"
  }
}
```

---

## 📊 Dashboard Stats API

### GET /dashboard/stats 🔒

Get dashboard statistics (Admin only).

**Response:**
```json
{
  "success": true,
  "stats": {
    "todayOrders": 5,
    "pendingOrders": 12,
    "totalRevenue": 125000,
    "lowStockProducts": 3
  }
}
```

---

## 🖼️ Image Upload API

### POST /upload/image 🔒

Upload product image to Cloudinary (Admin only).

**Headers:**
```
Authorization: Bearer <admin_token>
Content-Type: multipart/form-data
```

**Request Body (FormData):**
```
image: <file> (max 5MB, jpg/png/webp)
```

**Response:**
```json
{
  "success": true,
  "imageUrl": "https://res.cloudinary.com/coovi/image/upload/v1/products/image.jpg"
}
```

---

## ⚠️ Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Validation error",
  "errors": { /* field errors */ }
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Unauthorized. Please login."
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Access denied. Admin only."
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Internal server error",
  "error": "Error details (development mode only)"
}
```

---

## 📝 Testing with cURL

### Get Products
```bash
curl http://localhost:5000/api/products
```

### Create Order
```bash
curl -X POST http://localhost:5000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "Test User",
    "phone": "+8801712345678",
    "address": {
      "street": "123 Test St",
      "city": "Dhaka",
      "district": "Dhaka",
      "postalCode": "1200"
    },
    "items": [
      {
        "productId": "65a1b2c3d4e5f6789012345",
        "name": "Red Cotton Saree",
        "price": 1299,
        "quantity": 1,
        "image": "url"
      }
    ]
  }'
```

### Admin Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@coovi.com",
    "password": "password123"
  }'
```

### Create Product (with token)
```bash
curl -X POST http://localhost:5000/api/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "name": "New Saree",
    "slug": "new-saree",
    "price": 1999,
    "images": ["url1", "url2"],
    "category": "Saree",
    "stockCount": 10
  }'
```

---

**API documentation complete! Ready for frontend integration** 🎉
