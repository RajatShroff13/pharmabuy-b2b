"""
PharmaBuy B2B - Flask application

A pharmacy / pharmaceutical distribution portal built on Flask and Microsoft
SQL Server. All runtime configuration is read from environment variables so
no credentials are stored in the repository - see .env.example.
"""

import os
import secrets
from datetime import datetime, timedelta
from functools import wraps

import pyodbc
import requests as req
from dotenv import load_dotenv
from flask import (Flask, Response, flash, jsonify, redirect, render_template,
                   request, session, url_for)

load_dotenv()

app = Flask(__name__)
# A fixed SECRET_KEY keeps sessions alive across restarts; without one a random
# key is generated per boot (fine for local demo use).
app.secret_key = os.environ.get("SECRET_KEY") or secrets.token_hex(32)
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(hours=24)

# ------------------------- Database configuration -------------------------

DB_CONFIG = {
    'server': os.environ.get('DB_SERVER', r'localhost\SQLEXPRESS'),
    'database': os.environ.get('DB_NAME', 'Ph_Store'),
    'driver': os.environ.get('DB_DRIVER', 'ODBC Driver 17 for SQL Server'),
    'trusted_connection': os.environ.get('DB_TRUSTED_CONNECTION', 'yes'),
    'username': os.environ.get('DB_USERNAME', ''),
    'password': os.environ.get('DB_PASSWORD', ''),
}

# Optional n8n webhook that receives an invoice payload after each order
N8N_WEBHOOK_URL = os.environ.get(
    'N8N_WEBHOOK_URL', 'http://localhost:5678/webhook/pharmacy-invoice'
)


def get_db_connection():
    """Open a new connection to the SQL Server pharmacy database."""
    parts = [
        f"DRIVER={{{DB_CONFIG['driver']}}}",
        f"SERVER={DB_CONFIG['server']}",
        f"DATABASE={DB_CONFIG['database']}",
    ]

    if str(DB_CONFIG['trusted_connection']).lower() in ('yes', 'true', '1'):
        parts.append('Trusted_Connection=yes')
    else:
        parts.append(f"UID={DB_CONFIG['username']}")
        parts.append(f"PWD={DB_CONFIG['password']}")

    # Local SQL Server instances normally use a self-signed certificate.
    parts.append('TrustServerCertificate=yes')

    return pyodbc.connect(';'.join(parts) + ';')


@app.context_processor
def inject_template_globals():
    """Values every template can rely on (footer year, greeting date, ...)."""
    now = datetime.now()
    return {'now': now, 'current_year': now.year}

def login_required(f):
    """Decorator to require login"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please login to access this page.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorator to require admin/manager role"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session or session.get('role') not in ['ADMIN', 'MANAGER']:
            flash('Admin access required.', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

# ==================== AUTHENTICATION ROUTES ====================

@app.route('/')
def index():
    """Home page - redirect based on login status"""
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))


@app.route('/robots.txt')
def robots_txt():
    """Crawler rules - the portal is private, only the public pages are indexed."""
    lines = [
        'User-agent: *',
        'Allow: /login',
        'Allow: /register',
        'Disallow: /dashboard',
        'Disallow: /medicines',
        'Disallow: /cart',
        'Disallow: /checkout',
        'Disallow: /orders',
        'Disallow: /admin',
        'Disallow: /api/',
        'Disallow: /static/',
        f'Sitemap: {request.url_root.rstrip("/")}/sitemap.xml',
    ]
    return Response('\n'.join(lines), mimetype='text/plain')


@app.route('/sitemap.xml')
def sitemap_xml():
    """Minimal sitemap for the public entry pages."""
    pages = [
        (url_for('login', _external=True), '1.0'),
        (url_for('register', _external=True), '0.8'),
    ]
    urls = ''.join(
        f'  <url><loc>{loc}</loc><priority>{priority}</priority></url>\n'
        for loc, priority in pages
    )
    xml = ('<?xml version="1.0" encoding="UTF-8"?>\n'
           '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
           f'{urls}</urlset>\n')
    return Response(xml, mimetype='application/xml')


@app.errorhandler(404)
def page_not_found(error):
    """Friendly 404 instead of the default Werkzeug page."""
    return render_template('404.html'), 404

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Login page"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Check user credentials
            cursor.execute("""
                SELECT user_id, username, role 
                FROM User_Login 
                WHERE username = ? AND password = ?
            """, (username, password))
            
            user = cursor.fetchone()
            
            if user:
                session['user_id'] = user[0]
                session['username'] = user[1]
                session['role'] = user[2]
                session.permanent = True

                # Find linked customer_id by matching username (set during registration)
                cursor.execute("""
                    SELECT customer_id FROM Customer 
                    WHERE username = ?
                """, (user[1],))
                cust = cursor.fetchone()
                session['customer_id'] = cust[0] if cust else None
                
                flash(f'Welcome back, {username}!', 'success')
                return redirect(url_for('dashboard'))
            else:
                flash('Invalid username or password', 'danger')
            
            conn.close()
            
        except Exception as e:
            flash(f'Login error: {str(e)}', 'danger')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """Logout"""
    session.clear()
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('login'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    """Registration page for new customers"""
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Get form data
            username = request.form.get('username')
            password = request.form.get('password')
            customer_name = request.form.get('customer_name')
            phone = request.form.get('phone')
            email = request.form.get('email')
            address = request.form.get('address')
            
            # Check if username exists
            cursor.execute("SELECT user_id FROM User_Login WHERE username = ?", (username,))
            if cursor.fetchone():
                flash('Username already exists', 'danger')
                return render_template('register.html')
            
            # Create user login
            cursor.execute("""
                INSERT INTO User_Login (username, password, role)
                VALUES (?, ?, 'CUSTOMER')
            """, (username, password))
            
            # Create customer with email and username link
            cursor.execute("""
                INSERT INTO Customer (name, phone, email, address, username)
                VALUES (?, ?, ?, ?, ?)
            """, (customer_name, phone, email, address, username))
            
            conn.commit()
            conn.close()
            
            flash('Registration successful! Please login.', 'success')
            return redirect(url_for('login'))
            
        except Exception as e:
            flash(f'Registration error: {str(e)}', 'danger')
    
    return render_template('register.html')

# ==================== MAIN DASHBOARD ====================

@app.route('/dashboard')
@login_required
def dashboard():
    """Main dashboard - staff only"""
    if session.get('role') == 'CUSTOMER':
        return redirect(url_for('medicines'))
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get statistics
        cursor.execute("SELECT COUNT(*) FROM Medicine")
        total_medicines = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Category")
        total_categories = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Sales")
        total_orders = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT COUNT(*) FROM Batch 
            WHERE stock_qty < 20 AND expiry_date > GETDATE()
        """)
        low_stock = cursor.fetchone()[0]
        
        # Get recent medicines (batch filter belongs in the JOIN so medicines
        # whose batches have all expired still appear, flagged as out of stock)
        cursor.execute("""
            SELECT TOP 8 m.medicine_id, m.name, m.brand, c.category_name, m.mrp,
                   MIN(b.stock_qty) as stock_qty,
                   MIN(b.selling_price) as selling_price
            FROM Medicine m
            JOIN Category c ON m.category_id = c.category_id
            LEFT JOIN Batch b ON m.medicine_id = b.medicine_id
                 AND b.expiry_date > GETDATE() AND b.stock_qty > 0
            GROUP BY m.medicine_id, m.name, m.brand, c.category_name, m.mrp
            HAVING MIN(b.stock_qty) > 0
            ORDER BY m.medicine_id DESC
        """)
        
        recent_medicines = cursor.fetchall()
        
        conn.close()
        
        return render_template('dashboard.html',
                             total_medicines=total_medicines,
                             total_categories=total_categories,
                             total_orders=total_orders,
                             low_stock=low_stock,
                             recent_medicines=recent_medicines)
    
    except Exception as e:
        flash(f'Error loading dashboard: {str(e)}', 'danger')
        return render_template('dashboard.html', 
                             total_medicines=0, total_categories=0, 
                             total_orders=0, low_stock=0, recent_medicines=[])

# ==================== MEDICINE CATALOG ====================

@app.route('/medicines')
@login_required
def medicines():
    """Browse all medicines"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get filter parameters
        category_filter = request.args.get('category', '')
        search_query = request.args.get('search', '')
        
        # Base query
        query = """
            SELECT m.medicine_id, m.name, m.brand, c.category_name,
                   CAST(m.description AS VARCHAR(500)) as description,
                   m.mrp, m.gst_percent,
                   MIN(b.batch_id) as batch_id,
                   MIN(b.selling_price) as selling_price,
                   MIN(b.stock_qty) as stock_qty
            FROM Medicine m
            JOIN Category c ON m.category_id = c.category_id
            LEFT JOIN Batch b ON m.medicine_id = b.medicine_id 
            WHERE (b.expiry_date > GETDATE() OR b.expiry_date IS NULL)
        """
        
        params = []
        
        if category_filter:
            query += " AND c.category_name = ?"
            params.append(category_filter)
        
        if search_query:
            query += " AND (m.name LIKE ? OR m.brand LIKE ?)"
            params.extend([f'%{search_query}%', f'%{search_query}%'])
        
        query += " GROUP BY m.medicine_id, m.name, m.brand, c.category_name, CAST(m.description AS VARCHAR(500)), m.mrp, m.gst_percent"
        query += " ORDER BY m.name"
        
        cursor.execute(query, params)
        medicines = cursor.fetchall()
        
        # Get all categories for filter
        cursor.execute("SELECT category_name FROM Category ORDER BY category_name")
        categories = [row[0] for row in cursor.fetchall()]
        
        conn.close()
        
        return render_template('medicines.html', 
                             medicines=medicines,
                             categories=categories,
                             selected_category=category_filter,
                             search_query=search_query)
    
    except Exception as e:
        flash(f'Error loading medicines: {str(e)}', 'danger')
        return render_template('medicines.html', medicines=[], categories=[])

@app.route('/medicine/<int:medicine_id>')
@login_required
def medicine_detail(medicine_id):
    """Medicine detail page"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get medicine details
        cursor.execute("""
            SELECT m.medicine_id, m.name, m.brand, c.category_name, 
                   m.description, m.mrp, m.gst_percent
            FROM Medicine m
            JOIN Category c ON m.category_id = c.category_id
            WHERE m.medicine_id = ?
        """, (medicine_id,))
        
        medicine = cursor.fetchone()
        
        if not medicine:
            flash('Medicine not found', 'danger')
            return redirect(url_for('medicines'))
        
        # Get available batches
        cursor.execute("""
            SELECT batch_id, batch_no, manufacture_date, expiry_date,
                   selling_price, stock_qty, rack_location
            FROM Batch
            WHERE medicine_id = ? AND expiry_date > GETDATE() AND stock_qty > 0
            ORDER BY expiry_date
        """, (medicine_id,))
        
        batches = cursor.fetchall()
        
        conn.close()
        
        return render_template('medicine_detail.html', 
                             medicine=medicine,
                             batches=batches)
    
    except Exception as e:
        flash(f'Error loading medicine details: {str(e)}', 'danger')
        return redirect(url_for('medicines'))

# ==================== SHOPPING CART ====================

def build_cart_summary():
    """Resolve the session cart against the database.

    Returns a dict with the priced line items plus subtotal, GST and grand
    total. Shared by the cart page and the checkout page so both always show
    the same numbers.
    """
    cart_items = session.get('cart', {})
    summary = {'cart_items': [], 'subtotal': 0.0, 'gst': 0.0, 'total': 0.0, 'count': 0}

    if not cart_items:
        return summary

    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        for batch_id, quantity in cart_items.items():
            cursor.execute("""
                SELECT b.batch_id, m.name, m.brand, b.batch_no,
                       b.selling_price, b.stock_qty, m.gst_percent
                FROM Batch b
                JOIN Medicine m ON b.medicine_id = m.medicine_id
                WHERE b.batch_id = ?
            """, (batch_id,))

            batch = cursor.fetchone()
            if not batch:
                continue

            item_total = float(batch[4]) * quantity
            gst_percent = float(batch[6] or 0)
            gst_amount = item_total * (gst_percent / 100)

            summary['cart_items'].append({
                'batch_id': batch[0],
                'name': batch[1],
                'brand': batch[2],
                'batch_no': batch[3],
                'price': batch[4],
                'quantity': quantity,
                'stock_qty': batch[5],
                'gst_percent': gst_percent,
                'gst_amount': gst_amount,
                'subtotal': item_total,
                'total': item_total + gst_amount,
            })
            summary['subtotal'] += item_total
            summary['gst'] += gst_amount
    finally:
        conn.close()

    summary['total'] = summary['subtotal'] + summary['gst']
    summary['count'] = len(summary['cart_items'])
    return summary


@app.route('/cart')
@login_required
def cart():
    """View shopping cart"""
    try:
        summary = build_cart_summary()
        return render_template('cart.html', **summary)

    except Exception as e:
        flash(f'Error loading cart: {str(e)}', 'danger')
        return render_template('cart.html', cart_items=[], subtotal=0, gst=0,
                               total=0, count=0)

@app.route('/add_to_cart', methods=['POST'])
@login_required
def add_to_cart():
    """Add item to cart"""
    batch_id = request.form.get('batch_id')
    quantity = int(request.form.get('quantity', 1))
    
    if 'cart' not in session:
        session['cart'] = {}
    
    cart = session['cart']
    
    if batch_id in cart:
        cart[batch_id] += quantity
    else:
        cart[batch_id] = quantity
    
    session['cart'] = cart
    session.modified = True
    
    flash(f'Added {quantity} item(s) to cart', 'success')
    return redirect(request.referrer or url_for('medicines'))

@app.route('/update_cart', methods=['POST'])
@login_required
def update_cart():
    """Update cart quantities"""
    batch_id = request.form.get('batch_id')
    quantity = int(request.form.get('quantity', 0))
    
    if 'cart' in session:
        cart = session['cart']
        
        if quantity > 0:
            cart[batch_id] = quantity
        else:
            cart.pop(batch_id, None)
        
        session['cart'] = cart
        session.modified = True
        
        flash('Cart updated', 'success')
    
    return redirect(url_for('cart'))

@app.route('/remove_from_cart/<batch_id>')
@login_required
def remove_from_cart(batch_id):
    """Remove item from cart"""
    if 'cart' in session:
        cart = session['cart']
        cart.pop(batch_id, None)
        session['cart'] = cart
        session.modified = True
        flash('Item removed from cart', 'info')
    
    return redirect(url_for('cart'))

# ==================== CHECKOUT ====================

@app.route('/checkout', methods=['GET', 'POST'])
@login_required
def checkout():
    """Checkout page"""
    cart_items = session.get('cart', {})
    
    if not cart_items:
        flash('Your cart is empty', 'warning')
        return redirect(url_for('medicines'))
    
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Get customer information
            customer_name = request.form.get('customer_name')
            phone = request.form.get('phone')
            email = request.form.get('email')
            address = request.form.get('address')
            payment_mode = request.form.get('payment_mode')
            
            # Check if customer exists, else create
            cursor.execute("SELECT customer_id, email FROM Customer WHERE phone = ?", (phone,))
            customer = cursor.fetchone()
            
            if customer:
                customer_id = customer[0]
                # Update email if it was missing
                if not customer[1] and email:
                    cursor.execute("UPDATE Customer SET email = ? WHERE customer_id = ?", (email, customer_id))
            else:
                cursor.execute("""
                    INSERT INTO Customer (name, phone, email, address)
                    VALUES (?, ?, ?, ?)
                """, (customer_name, phone, email, address))
                customer_id = cursor.execute("SELECT @@IDENTITY").fetchval()
            
            # Get employee (use first available or session user)
            cursor.execute("SELECT TOP 1 employee_id FROM Employee")
            employee = cursor.fetchone()
            employee_id = employee[0] if employee else 1
            
            # Calculate total
            total_amount = 0
            items_data = []
            
            for batch_id, quantity in cart_items.items():
                cursor.execute("""
                    SELECT b.selling_price, b.stock_qty, m.gst_percent, m.name
                    FROM Batch b
                    JOIN Medicine m ON b.medicine_id = m.medicine_id
                    WHERE b.batch_id = ?
                """, (batch_id,))
                
                batch = cursor.fetchone()
                if batch:
                    price = batch[0]
                    stock_qty = batch[1]
                    gst_percent = batch[2]
                    medicine_name = batch[3]
                    
                    if stock_qty < quantity:
                        flash(f'Insufficient stock for batch {batch_id}', 'danger')
                        conn.close()
                        return redirect(url_for('cart'))
                    
                    item_total = price * quantity
                    gst_amount = item_total * (gst_percent / 100)
                    total_amount += item_total + gst_amount
                    
                    items_data.append({
                        'batch_id': batch_id,
                        'quantity': quantity,
                        'price': float(price),
                        'medicine_name': medicine_name
                    })
            
            # Create sales record
            cursor.execute("""
                INSERT INTO Sales (customer_id, employee_id, sales_date, total_amount)
                VALUES (?, ?, GETDATE(), ?)
            """, (customer_id, employee_id, total_amount))
            
            sales_id = cursor.execute("SELECT @@IDENTITY").fetchval()
            
            # Insert sales items and update stock
            for item in items_data:
                cursor.execute("""
                    INSERT INTO Sales_Items (sales_id, batch_id, quantity, selling_price)
                    VALUES (?, ?, ?, ?)
                """, (sales_id, item['batch_id'], item['quantity'], item['price']))
                
                # Update stock
                cursor.execute("""
                    UPDATE Batch SET stock_qty = stock_qty - ?
                    WHERE batch_id = ?
                """, (item['quantity'], item['batch_id']))
                
                # Log stock change
                cursor.execute("""
                    INSERT INTO Stock_Log (batch_id, change_type, qty, date)
                    VALUES (?, 'SALE', ?, GETDATE())
                """, (item['batch_id'], -item['quantity']))
            
            # Create payment record
            cursor.execute("""
                INSERT INTO Payment (sales_id, payment_mode, amount)
                VALUES (?, ?, ?)
            """, (sales_id, payment_mode, total_amount))
            
            conn.commit()

            # Save customer_id in session so My Orders works immediately
            session['customer_id'] = customer_id
            try:
                req.post(
                    N8N_WEBHOOK_URL,
                    json={
                        "order_id": int(sales_id),
                        "customer_name": customer_name,
                        "customer_email": email,
                        "total_amount": round(float(total_amount), 2),
                        "payment_mode": payment_mode,
                        "items": [
                            {
                                "medicine": item['medicine_name'],
                                "quantity": item['quantity'],
                                "price": item['price']
                            }
                            for item in items_data
                        ]
                    },
                    timeout=5
                )
            except Exception:
                pass  # Don't crash the order if webhook fails
            # ─────────────────────────────────────────────────────────

            conn.close()
            
            # Clear cart
            session.pop('cart', None)
            session.modified = True
            
            flash(f'Order #{sales_id} placed successfully!', 'success')
            return redirect(url_for('order_confirmation', order_id=sales_id))
            
        except Exception as e:
            flash(f'Checkout error: {str(e)}', 'danger')
            return redirect(url_for('cart'))
    
    # GET request - show checkout form with a live order summary
    try:
        summary = build_cart_summary()
    except Exception as e:
        flash(f'Error loading cart: {str(e)}', 'danger')
        return redirect(url_for('cart'))
    return render_template('checkout.html', **summary)

@app.route('/order_confirmation/<int:order_id>')
@login_required
def order_confirmation(order_id):
    """Order confirmation page"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get order details
        cursor.execute("""
            SELECT s.sales_id, s.sales_date, s.total_amount, 
                   c.name, c.phone, c.address,
                   p.payment_mode
            FROM Sales s
            JOIN Customer c ON s.customer_id = c.customer_id
            LEFT JOIN Payment p ON s.sales_id = p.sales_id
            WHERE s.sales_id = ?
        """, (order_id,))
        
        order = cursor.fetchone()
        
        # Get order items
        cursor.execute("""
            SELECT m.name, m.brand, b.batch_no, si.quantity, si.selling_price,
                   si.quantity * si.selling_price as subtotal
            FROM Sales_Items si
            JOIN Batch b ON si.batch_id = b.batch_id
            JOIN Medicine m ON b.medicine_id = m.medicine_id
            WHERE si.sales_id = ?
        """, (order_id,))
        
        items = cursor.fetchall()
        
        conn.close()
        
        return render_template('order_confirmation.html', 
                             order=order, 
                             items=items)
    
    except Exception as e:
        flash(f'Error loading order: {str(e)}', 'danger')
        return redirect(url_for('dashboard'))

# ==================== ORDER HISTORY ====================

@app.route('/orders')
@login_required
def orders():
    """View order history"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        if session.get('role') == 'CUSTOMER':
            # Customers see only their own orders
            customer_id = session.get('customer_id')
            if not customer_id:
                flash('No orders found for your account.', 'info')
                return render_template('orders.html', orders=[])
            cursor.execute("""
                SELECT s.sales_id, s.sales_date, c.name, s.total_amount, p.payment_mode
                FROM Sales s
                JOIN Customer c ON s.customer_id = c.customer_id
                LEFT JOIN Payment p ON s.sales_id = p.sales_id
                WHERE s.customer_id = ?
                ORDER BY s.sales_date DESC
            """, (customer_id,))
        else:
            # Staff see all orders
            cursor.execute("""
                SELECT s.sales_id, s.sales_date, c.name, s.total_amount, p.payment_mode
                FROM Sales s
                JOIN Customer c ON s.customer_id = c.customer_id
                LEFT JOIN Payment p ON s.sales_id = p.sales_id
                ORDER BY s.sales_date DESC
            """)

        orders = cursor.fetchall()
        conn.close()

        return render_template('orders.html', orders=orders)

    except Exception as e:
        flash(f'Error loading orders: {str(e)}', 'danger')
        return render_template('orders.html', orders=[])

@app.route('/order/<int:order_id>')
@login_required
def order_detail(order_id):
    """Order detail page"""
    return order_confirmation(order_id)

# ==================== ADMIN PANEL ====================

@app.route('/admin')
@admin_required
def admin_panel():
    """Admin dashboard"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get various statistics
        cursor.execute("SELECT COUNT(*) FROM Medicine")
        total_medicines = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Customer")
        total_customers = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Sales")
        total_sales = cursor.fetchone()[0]
        
        cursor.execute("SELECT SUM(total_amount) FROM Sales")
        total_revenue = cursor.fetchone()[0] or 0
        
        # Low stock items
        cursor.execute("""
            SELECT m.name, b.batch_no, b.stock_qty, b.expiry_date
            FROM Batch b
            JOIN Medicine m ON b.medicine_id = m.medicine_id
            WHERE b.stock_qty < 20 AND b.expiry_date > GETDATE()
            ORDER BY b.stock_qty
        """)
        
        low_stock_items = cursor.fetchall()
        
        conn.close()
        
        return render_template('admin.html',
                             total_medicines=total_medicines,
                             total_customers=total_customers,
                             total_sales=total_sales,
                             total_revenue=total_revenue,
                             low_stock_items=low_stock_items)
    
    except Exception as e:
        flash(f'Error loading admin panel: {str(e)}', 'danger')
        return render_template('admin.html')

# ==================== DB EXPLORER (ADMIN ONLY) ====================

@app.route('/admin/db-explorer')
@admin_required
def db_explorer():
    """Database table explorer - admin only"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Fetch all user-created table names from the database
        cursor.execute("""
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_TYPE = 'BASE TABLE'
            ORDER BY TABLE_NAME
        """)
        tables = [row[0] for row in cursor.fetchall()]
        conn.close()

        return render_template('db_explorer.html', tables=tables)

    except Exception as e:
        flash(f'Error loading DB Explorer: {str(e)}', 'danger')
        return redirect(url_for('admin_panel'))


@app.route('/admin/db-explorer/table')
@admin_required
def db_explorer_table():
    """Fetch rows for a selected table - admin only"""
    table_name = request.args.get('table', '')

    # Whitelist: only allow table names that actually exist in the DB
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_TYPE = 'BASE TABLE'
        """)
        valid_tables = [row[0] for row in cursor.fetchall()]

        if table_name not in valid_tables:
            return jsonify({'error': 'Invalid table name'}), 400

        # Get column names
        cursor.execute(f"SELECT TOP 0 * FROM [{table_name}]")
        columns = [desc[0] for desc in cursor.description]

        # Get all rows
        cursor.execute(f"SELECT * FROM [{table_name}]")
        rows = []
        for row in cursor.fetchall():
            rows.append([str(v) if v is not None else 'NULL' for v in row])

        conn.close()
        return jsonify({'columns': columns, 'rows': rows, 'table': table_name})

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==================== API ENDPOINTS ====================

@app.route('/api/search_medicines')
@login_required
def api_search_medicines():
    """API endpoint for medicine search"""
    query = request.args.get('q', '')
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT TOP 10 m.medicine_id, m.name, m.brand, c.category_name
            FROM Medicine m
            JOIN Category c ON m.category_id = c.category_id
            WHERE m.name LIKE ? OR m.brand LIKE ?
        """, (f'%{query}%', f'%{query}%'))
        
        results = []
        for row in cursor.fetchall():
            results.append({
                'id': row[0],
                'name': row[1],
                'brand': row[2],
                'category': row[3]
            })
        
        conn.close()
        return jsonify(results)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== REVENUE REPORT ====================

@app.route('/admin/revenue')
@admin_required
def revenue_report():
    """Revenue analytics page"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # --- Filter params ---
        mode     = request.args.get('mode', 'total')   # total | monthly | yearly
        month    = request.args.get('month', '')        # e.g. "2024-03"
        year     = request.args.get('year', '')         # e.g. "2024"

        # --- Build WHERE clause ---
        where = "WHERE 1=1"
        params = []
        if mode == 'monthly' and month:
            where += " AND FORMAT(s.sales_date, 'yyyy-MM') = ?"
            params.append(month)
        elif mode == 'yearly' and year:
            where += " AND YEAR(s.sales_date) = ?"
            params.append(int(year))

        # 1. Summary KPIs
        cursor.execute(f"""
            SELECT
                COUNT(DISTINCT s.sales_id)          AS total_orders,
                ISNULL(SUM(s.total_amount), 0)      AS total_revenue,
                ISNULL(AVG(s.total_amount), 0)      AS avg_order_value,
                COUNT(DISTINCT s.customer_id)       AS unique_customers
            FROM Sales s {where}
        """, params)
        kpi = cursor.fetchone()
        total_orders      = kpi[0]
        total_revenue     = float(kpi[1])
        avg_order_value   = float(kpi[2])
        unique_customers  = kpi[3]

        # 2. Revenue by payment mode (pie chart data)
        cursor.execute(f"""
            SELECT p.payment_mode, ISNULL(SUM(s.total_amount), 0) AS rev
            FROM Sales s
            JOIN Payment p ON s.sales_id = p.sales_id
            {where.replace('WHERE 1=1', 'WHERE 1=1')}
            GROUP BY p.payment_mode
            ORDER BY rev DESC
        """, params)
        payment_rows = cursor.fetchall()
        payment_labels = [r[0] for r in payment_rows]
        payment_values = [float(r[1]) for r in payment_rows]

        # 3. Revenue by category
        cursor.execute(f"""
            SELECT c.category_name, ISNULL(SUM(s.total_amount), 0) AS rev
            FROM Sales s
            JOIN Sales_Items si ON s.sales_id = si.sales_id
            JOIN Batch b        ON si.batch_id = b.batch_id
            JOIN Medicine m     ON b.medicine_id = m.medicine_id
            JOIN Category c     ON m.category_id = c.category_id
            {where}
            GROUP BY c.category_name
            ORDER BY rev DESC
        """, params)
        cat_rows   = cursor.fetchall()
        cat_labels = [r[0] for r in cat_rows]
        cat_values = [float(r[1]) for r in cat_rows]

        # 4. Top 5 selling medicines
        cursor.execute(f"""
            SELECT TOP 5
                m.name,
                SUM(si.quantity) AS units_sold,
                ISNULL(SUM(si.quantity * si.selling_price), 0) AS revenue
            FROM Sales s
            JOIN Sales_Items si ON s.sales_id = si.sales_id
            JOIN Batch b        ON si.batch_id = b.batch_id
            JOIN Medicine m     ON b.medicine_id = m.medicine_id
            {where}
            GROUP BY m.name
            ORDER BY revenue DESC
        """, params)
        top_medicines = cursor.fetchall()

        # 5. Top 5 customers by spend
        cursor.execute(f"""
            SELECT TOP 5
                c.name,
                COUNT(s.sales_id)             AS orders,
                ISNULL(SUM(s.total_amount), 0) AS total_spent
            FROM Sales s
            JOIN Customer c ON s.customer_id = c.customer_id
            {where}
            GROUP BY c.name
            ORDER BY total_spent DESC
        """, params)
        top_customers = cursor.fetchall()

        # 6. Daily/Monthly trend line
        if mode == 'monthly' and month:
            # Show day-by-day within the selected month
            cursor.execute(f"""
                SELECT DAY(s.sales_date) AS period,
                       ISNULL(SUM(s.total_amount), 0) AS rev
                FROM Sales s {where}
                GROUP BY DAY(s.sales_date)
                ORDER BY period
            """, params)
            trend_label = "Day"
        elif mode == 'yearly' and year:
            # Show month-by-month within the selected year
            cursor.execute(f"""
                SELECT MONTH(s.sales_date) AS period,
                       ISNULL(SUM(s.total_amount), 0) AS rev
                FROM Sales s {where}
                GROUP BY MONTH(s.sales_date)
                ORDER BY period
            """, params)
            trend_label = "Month"
        else:
            # Show year-by-year overall
            cursor.execute("""
                SELECT YEAR(s.sales_date) AS period,
                       ISNULL(SUM(s.total_amount), 0) AS rev
                FROM Sales s
                GROUP BY YEAR(s.sales_date)
                ORDER BY period
            """)
            trend_label = "Year"

        trend_rows   = cursor.fetchall()
        trend_labels = [str(r[0]) for r in trend_rows]
        trend_values = [float(r[1]) for r in trend_rows]

        # 7. Available years for the dropdown
        cursor.execute("SELECT DISTINCT YEAR(sales_date) FROM Sales ORDER BY 1 DESC")
        available_years = [str(r[0]) for r in cursor.fetchall()]

        conn.close()

        return render_template('revenue.html',
            mode=mode, month=month, year=year,
            total_orders=total_orders,
            total_revenue=total_revenue,
            avg_order_value=avg_order_value,
            unique_customers=unique_customers,
            payment_labels=payment_labels,
            payment_values=payment_values,
            cat_labels=cat_labels,
            cat_values=cat_values,
            top_medicines=top_medicines,
            top_customers=top_customers,
            trend_labels=trend_labels,
            trend_values=trend_values,
            trend_label=trend_label,
            available_years=available_years,
        )

    except Exception as e:
        flash(f'Error loading revenue report: {str(e)}', 'danger')
        return redirect(url_for('admin_panel'))
if __name__ == '__main__':
    # Debug is opt-in so a cloned repo never exposes the Werkzeug debugger.
    app.run(
        debug=os.environ.get('FLASK_DEBUG', '0') == '1',
        host=os.environ.get('HOST', '127.0.0.1'),
        port=int(os.environ.get('PORT', '5000')),
    )
